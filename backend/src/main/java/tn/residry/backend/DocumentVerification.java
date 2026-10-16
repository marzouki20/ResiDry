package tn.residry.backend;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.*;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.Timestamp;
import java.time.*;
import java.util.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/** The model supplies observations. A receipt binds server rules to exact documents and account. */
@Service
public class DocumentVerification {
    static final Set<String> REQUIRED = Set.of("FRONT", "BACK", "LICENSE_FRONT", "LICENSE_BACK", "INSURANCE", "TECHNICAL_INSPECTION");
    static Set<String> required(String vehicle) { var slots=new HashSet<>(REQUIRED); if("Moto".equals(vehicle)) slots.remove("TECHNICAL_INSPECTION"); return slots; }
    private final JdbcTemplate db;
    private final ObjectMapper json;
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build();
    @Value("${residry.ai.dossier-url:}") private String url;
    @Value("${residry.ai.token:}") private String token;
    public DocumentVerification(JdbcTemplate db, ObjectMapper json) { this.db=db; this.json=json; }

    public Map<String,Object> verify(AccountService.Account account, ApplicationService.Submission input) {
        validate(input);
        if(url.isBlank() || token.isBlank()) return Map.of("status","UNAVAILABLE","reason","verification_service_not_configured");
        try {
            var context = new LinkedHashMap<String,Object>();
            context.put("driver_name",account.name()); context.put("vehicle_type",input.vehicleType());
            context.put("declared_kg",input.declaredKg()); context.put("reserve_kg",input.reserveKg()); context.put("borrowed",input.borrowed());
            var documents=new TreeMap<>(input.documents()); documents.remove("VEHICLE_PHOTO");
            var request = HttpRequest.newBuilder(URI.create(url)).timeout(Duration.ofSeconds(320))
                .header("Authorization","Bearer "+token).header("Content-Type","application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json.writeValueAsString(Map.of("context",context,"documents",documents)))).build();
            var response = http.send(request,HttpResponse.BodyHandlers.ofString());
            if(response.statusCode()!=200) return Map.of("status","UNAVAILABLE","reason","verification_service_unavailable");
            @SuppressWarnings("unchecked") Map<String,Object> result=json.readValue(response.body(),Map.class);
            if(!Set.of("PASSED","BLOCKED").contains(result.get("status"))) return Map.of("status","UNAVAILABLE","reason","invalid_verification_response");
            if("PASSED".equals(result.get("status"))) {
                if(!validReport(result,input)) return Map.of("status","UNAVAILABLE","reason","incomplete_verification_report");
                String id=UUID.randomUUID().toString();
                db.update("INSERT INTO document_verifications VALUES (?,?,?,?,?)",id,account.id(),fingerprint(input),json.writeValueAsString(result),Timestamp.from(Instant.now().plusSeconds(1800)));
                result.put("verificationId",id); result.put("expiresInSeconds",1800);
            }
            return result;
        } catch(InterruptedException e) { Thread.currentThread().interrupt(); return Map.of("status","UNAVAILABLE","reason","verification_interrupted"); }
        catch(Exception e) { return Map.of("status","UNAVAILABLE","reason","verification_service_unavailable"); }
    }
    static void validate(ApplicationService.Submission input) {
        if(!input.consent()) throw new ApiException(HttpStatus.BAD_REQUEST,"consent_required");
        if(!Set.of("Moto","Voiture","Camionnette").contains(input.vehicleType())) throw new ApiException(HttpStatus.BAD_REQUEST,"motorized_vehicle_required");
        var docs=input.documents();
        if(!docs.keySet().containsAll(required(input.vehicleType())))
            throw new ApiException(HttpStatus.BAD_REQUEST,"all_driver_documents_required");
        if("Moto".equals(input.vehicleType()) && (!docs.containsKey("VEHICLE_PHOTO") || !"camera".equals(input.vehiclePhotoSource()) || input.declaredKg().doubleValue()>60)) throw new ApiException(HttpStatus.BAD_REQUEST,"motorcycle_photo_or_capacity_invalid");
        for(var content:docs.values()) {
            byte[] bytes;
            try { bytes=Base64.getDecoder().decode(content); } catch(Exception e) { throw new ApiException(HttpStatus.BAD_REQUEST,"invalid_document"); }
            if(bytes.length<8 || bytes.length>5*1024*1024) throw new ApiException(HttpStatus.BAD_REQUEST,"invalid_document_size");
            if(!((bytes[0]&255)==255 && (bytes[1]&255)==216 && (bytes[2]&255)==255) &&
                !Arrays.equals(Arrays.copyOf(bytes,8),new byte[]{(byte)137,80,78,71,13,10,26,10}))
                throw new ApiException(HttpStatus.BAD_REQUEST,"jpeg_or_png_required");
        }
    }
    @SuppressWarnings("unchecked")
    private boolean validReport(Map<String,Object> report,ApplicationService.Submission input) {
        if(!"tn-driver-documents-v4".equals(report.get("policy_version"))) return false;
        if(!(report.get("documents") instanceof List<?> docs) || !(report.get("checks") instanceof List<?> checks) || checks.isEmpty()) return false;
        var slots=new HashSet<String>();
        for(var item:docs) { if(!(item instanceof Map<?,?> d) || !"PASS".equals(d.get("status"))) return false; slots.add(String.valueOf(d.get("slot"))); }
        if(!slots.containsAll(required(input.vehicleType()))) return false;
        for(var item:checks) if(!(item instanceof Map<?,?> c) || !"PASS".equals(c.get("status"))) return false;
        var codes=new HashSet<String>(); for(var item:checks) codes.add(String.valueOf(((Map<?,?>)item).get("code")));
        if(!codes.containsAll(Set.of("tunisian_registration","registration_sides_match","tunisian_license","license_sides_match","driver_name_matches_license","vehicle_type_matches","license_validity","payload_readable","load_within_payload","license_category","insurance_validity","insurance_vehicle_matches","delivery_insurance_coverage"))) return false;
        if(!"Moto".equals(input.vehicleType()) && !codes.containsAll(Set.of("tunisian_inspection","inspection_validity","inspection_vehicle_matches","inspection_center"))) return false;
        if(!(report.get("payload_kg") instanceof Number payload) || !Double.isFinite(payload.doubleValue()) || payload.doubleValue()<=0 || payload.doubleValue()>10000 || input.declaredKg().add(input.reserveKg()).doubleValue()>payload.doubleValue()) return false;
        LocalDate today=LocalDate.now(ZoneId.of("Africa/Tunis"));
        return !LocalDate.parse((String)report.get("insurance_valid_until")).isBefore(today) && ("Moto".equals(input.vehicleType()) || !LocalDate.parse((String)report.get("inspection_valid_until")).isBefore(today));
    }
    public String requireReceipt(String accountId,ApplicationService.Submission input) {
        validate(input);
        var rows=db.queryForList("SELECT * FROM document_verifications WHERE id=? AND account_id=?",input.verificationId(),accountId);
        if(rows.isEmpty()) throw new ApiException(HttpStatus.BAD_REQUEST,"document_verification_required");
        var receipt=rows.get(0);
        if(((Timestamp)receipt.get("expires_at")).toInstant().isBefore(Instant.now()) || !fingerprint(input).equals(receipt.get("fingerprint")))
            throw new ApiException(HttpStatus.CONFLICT,"document_verification_expired_or_changed");
        return (String)receipt.get("result");
    }
    public void requireApproval(Map<String,Object> application, ApplicationService.Decision decision) {
        if(!"CONSISTENT".equals(application.get("ai_status")) || application.get("verification_id")==null)
            throw new ApiException(HttpStatus.BAD_REQUEST,"document_verification_required");
        try {
            var result=json.readValue((String)application.get("ai_result"),Map.class);
            if(!(result.get("payload_kg") instanceof Number payload) || decision.payloadKg()==null || decision.reserveKg()==null ||
                decision.payloadKg().doubleValue()>payload.doubleValue() || decision.reserveKg().compareTo((java.math.BigDecimal)application.get("reserve_kg"))<0) throw new IllegalArgumentException();
            LocalDate today=LocalDate.now(ZoneId.of("Africa/Tunis"));
            if(!"tn-driver-documents-v4".equals(result.get("policy_version")) || (!"Moto".equals(application.get("vehicle_type")) && LocalDate.parse((String)result.get("inspection_valid_until")).isBefore(today)) || LocalDate.parse((String)result.get("insurance_valid_until")).isBefore(today))
                throw new IllegalArgumentException();
        } catch(Exception e) { throw new ApiException(HttpStatus.BAD_REQUEST,"documents_expired_or_unverified"); }
    }
    private String fingerprint(ApplicationService.Submission input) {
        try {
            var canonical=new TreeMap<String,Object>(); canonical.put("vehicle",input.vehicleType()); canonical.put("declared",input.declaredKg().stripTrailingZeros().toPlainString());
            canonical.put("reserve",input.reserveKg().stripTrailingZeros().toPlainString()); canonical.put("borrowed",input.borrowed()); canonical.put("photo_source",String.valueOf(input.vehiclePhotoSource())); canonical.put("documents",new TreeMap<>(input.documents()));
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(json.writeValueAsString(canonical).getBytes(StandardCharsets.UTF_8)));
        } catch(Exception e) { throw new IllegalStateException(e); }
    }
}
