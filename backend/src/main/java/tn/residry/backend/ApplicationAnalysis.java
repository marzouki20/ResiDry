package tn.residry.backend;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.http.client.SimpleClientHttpRequestFactory;

@Service
public class ApplicationAnalysis {
    private final JdbcTemplate db;
    private final ObjectMapper json;
    @Value("${residry.ai.url}") private String endpoint;
    @Value("${residry.ai.token}") private String token;
    public ApplicationAnalysis(JdbcTemplate db,ObjectMapper json) { this.db=db; this.json=json; }
    @Async public void analyze(String id,int revision) {
        String status="UNAVAILABLE", result=null;
        try {
            var app=db.queryForMap("SELECT * FROM driver_applications WHERE id=? AND revision=?",id,revision);
            if(!"PENDING".equals(app.get("ai_status"))) return;
            if(!endpoint.isBlank() && !token.isBlank()) {
                var documents=db.queryForList("SELECT side,content_base64 FROM application_documents WHERE application_id=?",id);
                var front=documents.stream().filter(d -> d.get("side").equals("FRONT")).findFirst().orElseThrow();
                var back=documents.stream().filter(d -> d.get("side").equals("BACK")).findFirst().orElseThrow();
                var factory=new SimpleClientHttpRequestFactory(); factory.setConnectTimeout(10000); factory.setReadTimeout(100000);
                var response=RestClient.builder().requestFactory(factory).build().post().uri(endpoint)
                    .header("Authorization","Bearer "+token).body(Map.of("front",front.get("content_base64"),"back",back.get("content_base64"),
                        "vehicle_type",app.get("vehicle_type"),"declared_kg",app.get("declared_kg"),"reserve_kg",app.get("reserve_kg")))
                    .retrieve().body(Map.class);
                var ai=response==null?"":response.get("status");
                status="passed".equals(ai)?"CONSISTENT":"rejected".equals(ai)?"FLAGGED":"MANUAL_REVIEW";
                result=json.writeValueAsString(response);
            }
        } catch(Exception ignored) { /* No document or key logging; submission stays reviewable. */ }
        db.update("UPDATE driver_applications SET ai_status=?,ai_result=? WHERE id=? AND revision=? AND ai_status='PENDING'",
            status,result,id,revision);
    }
}
