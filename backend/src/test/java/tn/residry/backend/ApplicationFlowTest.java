package tn.residry.backend;

import java.util.*;
import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.jdbc.core.JdbcTemplate;
import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment=SpringBootTest.WebEnvironment.RANDOM_PORT, properties={
    "spring.datasource.url=jdbc:h2:mem:flow;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE",
    "residry.admin.email=reviewer@test.tn", "residry.admin.password=Coursework-Test-Password-123"})
class ApplicationFlowTest {
    static final HttpServer vision;
    static volatile boolean unavailable=false;
    static {
        try {
            vision=HttpServer.create(new InetSocketAddress("127.0.0.1",0),0);
            vision.createContext("/verify-dossier",exchange -> {
                exchange.getRequestBody().readAllBytes();
                var checks=List.of("tunisian_registration","registration_sides_match","tunisian_license","license_sides_match","driver_name_matches_license","vehicle_type_matches","license_validity","payload_readable","load_within_payload","license_category","insurance_validity","insurance_vehicle_matches","delivery_insurance_coverage","tunisian_inspection","inspection_validity","inspection_vehicle_matches","inspection_center").stream().map(c -> Map.of("code",c,"status","PASS")).toList();
                var docs=DocumentVerification.REQUIRED.stream().map(c -> Map.of("slot",c,"status","PASS")).toList();
                var result=Map.of("status","PASSED","policy_version","tn-driver-documents-v4","documents",docs,"checks",checks,"payload_kg",410,"license_valid_until","2035-01-01","insurance_valid_until","2035-01-01","inspection_valid_until","2035-01-01");
                byte[] body=new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsBytes(result);
                exchange.getResponseHeaders().set("Content-Type","application/json"); exchange.sendResponseHeaders(unavailable?503:200,body.length);
                exchange.getResponseBody().write(body);exchange.close();
            }); vision.start();
        } catch(Exception e) { throw new ExceptionInInitializerError(e); }
    }
    @DynamicPropertySource static void properties(DynamicPropertyRegistry registry) {
        registry.add("residry.ai.dossier-url",() -> "http://127.0.0.1:"+vision.getAddress().getPort()+"/verify-dossier");
        registry.add("residry.ai.token",() -> "test-token");
    }
    @AfterAll static void stopVision() { vision.stop(0); }
    @Autowired TestRestTemplate http;
    @Autowired JdbcTemplate db;
    Map session(String role) {
        return http.postForObject("/api/auth/register",Map.of("name","Test Driver","email",UUID.randomUUID()+"@test.tn",
            "password","Coursework-Password-123","role",role,"phone","+21655123456"),Map.class);
    }
    Map admin() { return http.postForObject("/api/auth/login",Map.of("email","reviewer@test.tn","password","Coursework-Test-Password-123"),Map.class); }
    ResponseEntity<Map> call(String path,HttpMethod method,Map session,Object body) {
        var headers=new HttpHeaders(); headers.setBearerAuth((String)session.get("token"));
        headers.setContentType(MediaType.APPLICATION_JSON);
        return http.exchange(path,method,new HttpEntity<>(body,headers),Map.class);
    }
    Map<String,Object> application() {
        var image=Base64.getEncoder().encodeToString(new byte[]{(byte)255,(byte)216,(byte)255,1,2,3,4,5});
        var result = new HashMap<String,Object>(Map.of("vehicleType","Camionnette","declaredKg",200,"reserveKg",100,
            "zones",List.of("11","61"),"consent",true,"front",image,"back",image));
        result.put("licenseFront",image);result.put("licenseBack",image);result.put("insurance",image);result.put("technicalInspection",image);return result;
    }
    Map<String,Object> verified(Map driver) {
        var input=application();
        var response=call("/api/driver/application/verify-documents",HttpMethod.POST,driver,input);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().get("status")).isEqualTo("PASSED");
        input.put("verificationId",response.getBody().get("verificationId")); return input;
    }
    @Test void verifiedSubmissionSupportsCorrectionResubmissionApproval() {
        var driver=session("DRIVER"); var reviewer=admin();
        var draft=call("/api/driver/application/draft",HttpMethod.PUT,driver,application());
        assertThat(draft.getBody().get("status")).isEqualTo("DRAFT");
        var submitted=call("/api/driver/application/submit",HttpMethod.POST,driver,verified(driver)).getBody();
        assertThat(submitted.get("status")).isEqualTo("SUBMITTED");
        assertThat(submitted.get("can_receive_missions")).isEqualTo(false);
        var id=submitted.get("id"); int version=((Number)submitted.get("revision")).intValue();
        var correction=call("/api/admin/applications/"+id+"/review",HttpMethod.POST,reviewer,
            Map.of("revision",version,"status","CORRECTION_REQUESTED","reason","Please provide clearer photos","identityChecked",false));
        assertThat(correction.getBody().get("status")).isEqualTo("CORRECTION_REQUESTED");
        var resubmitted=call("/api/driver/application/submit",HttpMethod.POST,driver,verified(driver)).getBody();
        version=((Number)resubmitted.get("revision")).intValue();
        var approved=call("/api/admin/applications/"+id+"/review",HttpMethod.POST,reviewer,
            Map.of("revision",version,"status","APPROVED","reason","Identity and weights checked against documents",
                "identityChecked",true,"payloadKg",410,"reserveKg",100));
        assertThat(approved.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(approved.getBody().get("can_receive_missions")).isEqualTo(true);
        assertThat((List)approved.getBody().get("events")).hasSize(5);
        assertThat(call("/api/driver/application",HttpMethod.GET,driver,null).getBody().get("status")).isEqualTo("APPROVED");
        assertThat(call("/api/driver/application/draft",HttpMethod.PUT,driver,application()).getBody().get("can_receive_missions")).isEqualTo(false);
    }
    @Test void outageMissingReceiptTamperingAndExpiryBlockSubmission() {
        var driver=session("DRIVER");
        assertThat(call("/api/driver/application/submit",HttpMethod.POST,driver,application()).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        unavailable=true;
        try { assertThat(call("/api/driver/application/verify-documents",HttpMethod.POST,driver,application()).getBody().get("status")).isEqualTo("UNAVAILABLE"); }
        finally { unavailable=false; }
        var input=verified(driver); input.put("declaredKg",201);
        assertThat(call("/api/driver/application/submit",HttpMethod.POST,driver,input).getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        input=verified(driver);input.put("front",Base64.getEncoder().encodeToString(new byte[]{(byte)255,(byte)216,(byte)255,9,8,7,6,5}));
        assertThat(call("/api/driver/application/submit",HttpMethod.POST,driver,input).getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        input=verified(driver);db.update("UPDATE document_verifications SET expires_at=? WHERE id=?",java.sql.Timestamp.from(java.time.Instant.now().minusSeconds(1)),input.get("verificationId"));
        assertThat(call("/api/driver/application/submit",HttpMethod.POST,driver,input).getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        var other=session("DRIVER");input=verified(driver);
        assertThat(call("/api/driver/application/submit",HttpMethod.POST,other,input).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(call("/api/driver/application",HttpMethod.GET,driver,null).getBody().get("status")).isEqualTo("NOT_STARTED");
    }
    @Test void driverCannotAccessAdminDocumentsOrBecomeAdminBySignup() {
        var driver=session("DRIVER");
        assertThat(call("/api/admin/applications",HttpMethod.GET,driver,null).getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        assertThat(http.postForEntity("/api/auth/register",Map.of("name","Bad","email","bad@test.tn","password","LongPassword123","role","ADMIN"),Map.class).getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        assertThat(http.getForEntity("/api/admin/applications",String.class).getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }
    @Test void approvalRejectsOverloadStaleRevisionAndMissingReason() {
        var driver=session("DRIVER"); var reviewer=admin();
        var submitted=call("/api/driver/application/submit",HttpMethod.POST,driver,verified(driver)).getBody();
        var path="/api/admin/applications/"+submitted.get("id")+"/review";
        var decision=new HashMap<String,Object>(Map.of("revision",1,"status","APPROVED","reason","Checked","identityChecked",true,"payloadKg",100,"reserveKg",100));
        assertThat(call(path,HttpMethod.POST,reviewer,decision).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        decision.put("revision",99);
        assertThat(call(path,HttpMethod.POST,reviewer,decision).getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        decision.put("revision",1); decision.put("reason","");
        assertThat(call(path,HttpMethod.POST,reviewer,decision).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(call("/api/driver/application",HttpMethod.GET,driver,null).getBody().get("status")).isEqualTo("SUBMITTED");
    }
    @Test void invalidPhoneDocumentsAndZonesDoNotSaveApplications() {
        assertThat(http.postForEntity("/api/auth/register",Map.of("name","Bad","email","phone@test.tn","password","LongPassword123","role","DRIVER","phone","+21611123456"),Map.class).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        var driver=session("DRIVER"); var input=application(); input.put("zones",List.of("99"));
        assertThat(call("/api/driver/application/submit",HttpMethod.POST,driver,input).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        input=application(); input.remove("back");
        assertThat(call("/api/driver/application/submit",HttpMethod.POST,driver,input).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        input=application(); input.put("front","bm90IGFuIGltYWdl");
        assertThat(call("/api/driver/application/submit",HttpMethod.POST,driver,input).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(call("/api/driver/application",HttpMethod.GET,driver,null).getBody().get("status")).isEqualTo("NOT_STARTED");
    }
    @Test void lightVehicleLimitsPhotosAndManualApprovalAreEnforced() {
        var reviewer=admin();
        for(var vehicle:List.of("Moto","V\u00e9lo")) {
            int limit=vehicle.equals("Moto")?60:20;
            var driver=session("DRIVER");var input=application();
            input.put("vehicleType",vehicle);input.put("declaredKg",limit+1);input.put("reserveKg",0);
            assertThat(call("/api/driver/application/draft",HttpMethod.PUT,driver,input).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
            input.put("declaredKg",limit);
            assertThat(call("/api/driver/application/submit",HttpMethod.POST,driver,input).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
            input.put("vehiclePhoto",input.get("front"));input.put("vehiclePhotoSource","gallery");
            if(vehicle.equals("Moto")) {
                assertThat(call("/api/driver/application/submit",HttpMethod.POST,driver,input).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
                input.put("vehiclePhotoSource","camera");
            }
            if(vehicle.equals("Moto")) {
                input.remove("technicalInspection"); input.put("reserveKg",70);
                assertThat(call("/api/driver/application/submit",HttpMethod.POST,driver,input).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
                var verification=call("/api/driver/application/verify-documents",HttpMethod.POST,driver,input);
                assertThat(verification.getStatusCode()).isEqualTo(HttpStatus.OK);
                input.put("verificationId",verification.getBody().get("verificationId"));
            } else for(var key:List.of("front","back","licenseFront","licenseBack","insurance","technicalInspection")) input.remove(key);
            var response=call("/api/driver/application/submit",HttpMethod.POST,driver,input);
            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
            var saved=response.getBody(); assertThat(saved.get("ai_status")).isEqualTo(vehicle.equals("Moto")?"CONSISTENT":"MANUAL_REVIEW");
            assertThat(saved.get("can_receive_missions")).isEqualTo(false);
            var decision=Map.of("revision",saved.get("revision"),"status","APPROVED","reason","Vehicle photo reviewed","identityChecked",true,"payloadKg",vehicle.equals("Moto")?410:limit,"reserveKg",vehicle.equals("Moto")?70:0);
            assertThat(call("/api/admin/applications/"+saved.get("id")+"/review",HttpMethod.POST,reviewer,decision).getStatusCode()).isEqualTo(HttpStatus.OK);
        }
    }
    @Test void missingInspectionCannotVerifyOrSubmit() {
        var driver=session("DRIVER"); var input=application();input.remove("technicalInspection");
        assertThat(call("/api/driver/application/verify-documents",HttpMethod.POST,driver,input).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(call("/api/driver/application/submit",HttpMethod.POST,driver,input).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(call("/api/driver/application/draft",HttpMethod.PUT,driver,input).getBody().get("status")).isEqualTo("DRAFT");
    }
    @Test void duplicateEmailReturnsSpecificErrorWithoutReplacingAccount() {
        var existing=session("DRIVER"); var account=(Map)existing.get("account");
        var response=http.postForEntity("/api/auth/register",Map.of("name","Another Driver","email",account.get("email"),"password","DifferentPassword123","role","DRIVER","phone","+21655123456"),Map.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(response.getBody().get("error")).isEqualTo("email_already_registered");
        assertThat(db.queryForObject("SELECT COUNT(*) FROM accounts WHERE email=?",Integer.class,account.get("email"))).isEqualTo(1);
    }
    @Test void logoutRevokesTokenAndPasswordsAreHashed() {
        var driver=session("DRIVER"); var account=(Map)driver.get("account");
        var hash=db.queryForObject("SELECT password_hash FROM accounts WHERE id=?",String.class,account.get("id"));
        assertThat(hash).startsWith("$2a$").doesNotContain("Coursework");
        call("/api/auth/logout",HttpMethod.POST,driver,null);
        assertThat(call("/api/driver/application",HttpMethod.GET,driver,null).getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }
}
