package tn.residry.backend;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.*;
import jakarta.validation.constraints.*;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ApplicationService {
    public record Submission(@NotBlank String vehicleType, @NotNull @DecimalMin("0.1") @DecimalMax("10000") BigDecimal declaredKg,
        @NotNull @DecimalMin("0") @DecimalMax("10000") BigDecimal reserveKg, @NotNull Set<String> zones,
        boolean consent, @Size(max=7000000) String front, @Size(max=7000000) String back,
        @Size(max=7000000) String licenseFront, @Size(max=7000000) String licenseBack,
        @Size(max=7000000) String insurance, @Size(max=7000000) String authorization,
        @Size(max=7000000) String technicalInspection, @Size(max=7000000) String vehiclePhoto, @Size(max=10) String vehiclePhotoSource, boolean borrowed, @Size(max=36) String verificationId) {
        public Map<String,String> documents() {
            var result=new TreeMap<String,String>();
            String[] slots={"FRONT","BACK","LICENSE_FRONT","LICENSE_BACK","INSURANCE","AUTHORIZATION","TECHNICAL_INSPECTION","VEHICLE_PHOTO"};
            String[] values={front,back,licenseFront,licenseBack,insurance,authorization,technicalInspection,vehiclePhoto};
            for(int i=0;i<slots.length;i++) if(values[i]!=null && !values[i].isBlank()) result.put(slots[i],values[i]);
            return result;
        }
        @Override public String toString() { return "Submission[documents redacted]"; }
    }
    public record Decision(@Min(1) int revision, @NotBlank String status, @NotBlank @Size(max=2000) String reason,
        boolean identityChecked, BigDecimal payloadKg, BigDecimal reserveKg) {}
    private static final Set<String> ZONES = Set.of("11","12","13","14","21","22","23","31","32","33","34","41","42","43","51","52","53","61","71","72","73","81","82","83");
    private final JdbcTemplate db;
    private final ObjectMapper json;
    private final DocumentVerification verification;
    public ApplicationService(JdbcTemplate db, ObjectMapper json, DocumentVerification verification) { this.db = db; this.json = json; this.verification=verification; }

    static boolean light(String vehicle) { return Set.of("Moto","V\u00e9lo").contains(vehicle); }
    static int capacityLimit(String vehicle) { return "Moto".equals(vehicle)?60:"V\u00e9lo".equals(vehicle)?20:10000; }
    public Map<String,Object> mine(String accountId) {
        var rows = db.queryForList("SELECT d.*, a.name, a.email, a.phone FROM driver_applications d JOIN accounts a ON d.account_id=a.id WHERE d.account_id=?", accountId);
        return rows.isEmpty() ? Map.of("status", "NOT_STARTED") : view(rows.get(0));
    }
    private Map<String,Object> view(Map<String,Object> row) {
        var result = new LinkedHashMap<>(row);
        try { result.put("zones", json.readValue((String)row.get("zones"), List.class)); }
        catch(Exception e) { throw new IllegalStateException(e); }
        result.put("document_slots",db.queryForList("SELECT side FROM application_documents WHERE application_id=? UNION ALL SELECT side FROM application_supporting_documents WHERE application_id=?",row.get("id"),row.get("id")).stream().map(d -> d.get("side")).toList());
        result.put("can_receive_missions", "APPROVED".equals(row.get("status")));
        var sides=db.queryForList("SELECT side FROM application_documents WHERE application_id=?",row.get("id"));
        result.put("has_front",sides.stream().anyMatch(d -> d.get("side").equals("FRONT")));
        result.put("has_back",sides.stream().anyMatch(d -> d.get("side").equals("BACK")));
        return result;
    }
    public List<Map<String,Object>> list() {
        return db.queryForList("SELECT d.*,a.name,a.email,a.phone FROM driver_applications d JOIN accounts a ON d.account_id=a.id WHERE d.status!='DRAFT' ORDER BY d.updated_at DESC")
            .stream().map(this::view).toList();
    }
    public Map<String,Object> detail(String id) {
        var rows = db.queryForList("SELECT d.*,a.name,a.email,a.phone FROM driver_applications d JOIN accounts a ON d.account_id=a.id WHERE d.id=?", id);
        if(rows.isEmpty()) throw new ApiException(HttpStatus.NOT_FOUND,"application_not_found");
        var result = view(rows.get(0));
        result.put("documents", db.queryForList("SELECT side,mime_type FROM application_documents WHERE application_id=? UNION ALL SELECT side,mime_type FROM application_supporting_documents WHERE application_id=?",id,id));
        result.put("events", db.queryForList("SELECT event_type,revision,details,occurred_at FROM application_events WHERE application_id=? ORDER BY occurred_at",id));
        return result;
    }
    @Transactional public Map<String,Object> save(String accountId, Submission input, boolean submit) {
        if (!Set.of("Moto","Voiture","Camionnette","Vélo").contains(input.vehicleType()) || !ZONES.containsAll(input.zones()))
            throw new IllegalArgumentException();
        if(input.declaredKg().compareTo(BigDecimal.valueOf(capacityLimit(input.vehicleType())))>0) throw new ApiException(HttpStatus.BAD_REQUEST,"vehicle_capacity_limit_exceeded");
        if(submit && light(input.vehicleType()) && (input.vehiclePhoto()==null || input.vehiclePhoto().isBlank())) throw new ApiException(HttpStatus.BAD_REQUEST,"vehicle_photo_required");
        if(submit && "Moto".equals(input.vehicleType()) && !"camera".equals(input.vehiclePhotoSource())) throw new ApiException(HttpStatus.BAD_REQUEST,"motorcycle_camera_photo_required");
        if(submit && light(input.vehicleType()) && !Set.of("camera","gallery").contains(String.valueOf(input.vehiclePhotoSource()))) throw new ApiException(HttpStatus.BAD_REQUEST,"vehicle_photo_source_required");
        if(submit && !input.consent()) throw new ApiException(HttpStatus.BAD_REQUEST,"consent_required");
        if(submit && input.zones().isEmpty()) throw new ApiException(HttpStatus.BAD_REQUEST,"zones_required");
        if(submit && !"V\u00e9lo".equals(input.vehicleType()) && (input.front()==null || input.back()==null || input.front().isBlank() || input.back().isBlank()))
            throw new ApiException(HttpStatus.BAD_REQUEST,"both_certificate_sides_required");
        String verifiedResult=submit && !"V\u00e9lo".equals(input.vehicleType()) ? verification.requireReceipt(accountId,input) : null;
        var existing = db.queryForList("SELECT * FROM driver_applications WHERE account_id=? FOR UPDATE",accountId);
        var id = existing.isEmpty() ? UUID.randomUUID().toString() : (String)existing.get(0).get("id");
        int revision = existing.isEmpty() ? 1 : ((Number)existing.get(0).get("revision")).intValue()+1;
        var now = Timestamp.from(Instant.now());
        var status = submit ? "SUBMITTED" : "DRAFT";
        var aiStatus = submit ? ("V\u00e9lo".equals(input.vehicleType()) ? "MANUAL_REVIEW" : "PENDING") : "NOT_REQUESTED";
        String zones;
        try { zones=json.writeValueAsString(new TreeSet<>(input.zones())); } catch(Exception e) { throw new IllegalArgumentException(); }
        if (existing.isEmpty()) {
            db.update("INSERT INTO driver_applications (id,account_id,status,vehicle_type,declared_kg,reserve_kg,zones,consent,revision,ai_status,updated_at,submitted_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
                id,accountId,status,input.vehicleType(),input.declaredKg(),input.reserveKg(),zones,input.consent(),revision,aiStatus,now,submit?now:null);
        } else {
            db.update("UPDATE driver_applications SET status=?,vehicle_type=?,declared_kg=?,reserve_kg=?,zones=?,consent=?,revision=?,ai_status=?,ai_result=NULL,confirmed_payload_kg=NULL,confirmed_reserve_kg=NULL,review_reason=NULL,submitted_at=?,updated_at=? WHERE id=?",
                status,input.vehicleType(),input.declaredKg(),input.reserveKg(),zones,input.consent(),revision,aiStatus,submit?now:null,now,id);
        }
        db.update("DELETE FROM application_documents WHERE application_id=?",id);
        document(id,"FRONT",input.front()); document(id,"BACK",input.back());
        db.update("DELETE FROM application_supporting_documents WHERE application_id=?",id);
        for(var entry:input.documents().entrySet()) if(!Set.of("FRONT","BACK").contains(entry.getKey())) document(id,entry.getKey(),entry.getValue());
        db.update("UPDATE driver_applications SET borrowed=?,verification_id=?,ai_status=?,ai_result=? WHERE id=?", input.borrowed(), verifiedResult==null?null:input.verificationId(),verifiedResult==null?aiStatus:"CONSISTENT",verifiedResult,id);
        db.update("UPDATE driver_applications SET vehicle_photo_source=? WHERE id=?",input.vehiclePhotoSource(),id);
        event(id,accountId,submit?"SUBMITTED":"DRAFT_SAVED",revision,"{}");
        return mine(accountId);
    }
    private void document(String id,String side,String content) {
        if(content==null || content.isBlank()) return;
        byte[] bytes;
        try { bytes=Base64.getDecoder().decode(content); } catch(Exception e) { throw new IllegalArgumentException(); }
        if(bytes.length < 8 || bytes.length > 5*1024*1024) throw new ApiException(HttpStatus.BAD_REQUEST,"invalid_document_size");
        String mime;
        if((bytes[0]&255)==255 && (bytes[1]&255)==216 && (bytes[2]&255)==255) mime="image/jpeg";
        else if(Arrays.equals(Arrays.copyOf(bytes,8),new byte[]{(byte)137,80,78,71,13,10,26,10})) mime="image/png";
        else throw new ApiException(HttpStatus.BAD_REQUEST,"jpeg_or_png_required");
        db.update("INSERT INTO "+(Set.of("FRONT","BACK").contains(side)?"application_documents":"application_supporting_documents")+" VALUES (?,?,?,?)",id,side,mime,content);
    }
    public Map<String,Object> document(String id,String side) {
        var rows=db.queryForList("SELECT mime_type,content_base64 FROM application_documents WHERE application_id=? AND side=? UNION ALL SELECT mime_type,content_base64 FROM application_supporting_documents WHERE application_id=? AND side=?",id,side,id,side);
        if(rows.isEmpty()) throw new ApiException(HttpStatus.NOT_FOUND,"document_not_found");
        return rows.get(0);
    }
    @Transactional public Map<String,Object> review(String id,String reviewer,Decision input) {
        var rows=db.queryForList("SELECT * FROM driver_applications WHERE id=? FOR UPDATE",id);
        if(rows.isEmpty()) throw new ApiException(HttpStatus.NOT_FOUND,"application_not_found");
        var current=rows.get(0);
        int revision=((Number)current.get("revision")).intValue();
        if(revision!=input.revision()) throw new ApiException(HttpStatus.CONFLICT,"stale_application");
        if(!Set.of("SUBMITTED","UNDER_REVIEW").contains(current.get("status")))
            throw new ApiException(HttpStatus.CONFLICT,"application_not_reviewable");
        if(!Set.of("UNDER_REVIEW","CORRECTION_REQUESTED","APPROVED","REJECTED").contains(input.status())) throw new IllegalArgumentException();
        if(input.status().equals("APPROVED") && !"V\u00e9lo".equals(current.get("vehicle_type"))) verification.requireApproval(current,input);
        if(input.status().equals("APPROVED") && light((String)current.get("vehicle_type"))) {
            if(db.queryForObject("SELECT COUNT(*) FROM application_supporting_documents WHERE application_id=? AND side='VEHICLE_PHOTO'",Integer.class,id)!=1 ||
               ("Moto".equals(current.get("vehicle_type")) && !"camera".equals(current.get("vehicle_photo_source"))) || input.payloadKg()==null || ("V\u00e9lo".equals(current.get("vehicle_type")) && input.payloadKg().compareTo(BigDecimal.valueOf(20))>0))
                throw new ApiException(HttpStatus.BAD_REQUEST,"vehicle_photo_or_capacity_invalid");
        }
        var declared=(BigDecimal)current.get("declared_kg");
        if(input.status().equals("APPROVED") && (!input.identityChecked() || input.payloadKg()==null || input.reserveKg()==null ||
            input.payloadKg().signum()<=0 || input.payloadKg().compareTo(BigDecimal.valueOf(10000))>0 || input.reserveKg().signum()<0 ||
            declared.add(input.reserveKg()).compareTo(input.payloadKg())>0))
            throw new ApiException(HttpStatus.BAD_REQUEST,"confirmed_capacity_or_identity_invalid");
        db.update("UPDATE driver_applications SET status=?,review_reason=?,confirmed_payload_kg=?,confirmed_reserve_kg=?,revision=revision+1,updated_at=? WHERE id=?",
            input.status(),input.reason().trim(),input.payloadKg(),input.reserveKg(),Timestamp.from(Instant.now()),id);
        try { event(id,reviewer,input.status(),revision+1,json.writeValueAsString(Map.of("reason",input.reason(),"identityChecked",input.identityChecked(),
            "previousPayload",String.valueOf(current.get("confirmed_payload_kg")),"payload",String.valueOf(input.payloadKg()),
            "previousReserve",String.valueOf(current.get("confirmed_reserve_kg")),"reserve",String.valueOf(input.reserveKg())))); }
        catch(Exception e) { throw new IllegalStateException(e); }
        return detail(id);
    }
    private void event(String id,String actor,String type,int revision,String details) {
        db.update("INSERT INTO application_events VALUES (?,?,?,?,?,?,?)", UUID.randomUUID().toString(),id,actor,type,revision,details,Timestamp.from(Instant.now()));
    }
}
