package tn.residry.backend;

import jakarta.validation.Valid;
import java.util.*;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class ApiController {
    private final AccountService accounts;
    private final ApplicationService applications;
    private final DocumentVerification verification;
    public ApiController(AccountService a,ApplicationService s,DocumentVerification ai) { accounts=a;applications=s;verification=ai; }
    @GetMapping("/health") Map<String,String> health() { return Map.of("status","UP"); }
    @PostMapping("/auth/register") AccountService.Session register(@Valid @RequestBody AccountService.Registration r) { return accounts.register(r); }
    @PostMapping("/auth/login") AccountService.Session login(@Valid @RequestBody AccountService.Login r) { return accounts.login(r); }
    @PostMapping("/auth/logout") void logout(@RequestHeader("Authorization") String header) { accounts.logout(header.substring(7)); }
    @GetMapping("/driver/application") Map<String,Object> mine(@AuthenticationPrincipal AccountService.Account a) { return applications.mine(a.id()); }
    @GetMapping("/driver/application/documents/{side}") ResponseEntity<byte[]> ownDocument(@AuthenticationPrincipal AccountService.Account a,@PathVariable String side) {
        var application=applications.mine(a.id());
        if(!application.containsKey("id")) throw new ApiException(HttpStatus.NOT_FOUND,"document_not_found");
        return document((String)application.get("id"),side);
    }
    @PutMapping("/driver/application/draft") Map<String,Object> draft(@AuthenticationPrincipal AccountService.Account a,@Valid @RequestBody ApplicationService.Submission r) { return applications.save(a.id(),r,false); }
    @PostMapping("/driver/application/submit") Map<String,Object> submit(@AuthenticationPrincipal AccountService.Account a,@Valid @RequestBody ApplicationService.Submission r) {
        var saved=applications.save(a.id(),r,true);

        return saved;
    }
    @PostMapping("/driver/application/verify-documents") Map<String,Object> verify(@AuthenticationPrincipal AccountService.Account a,@Valid @RequestBody ApplicationService.Submission r) { return verification.verify(a,r); }
    @GetMapping("/admin/applications") List<Map<String,Object>> list() { return applications.list(); }
    @GetMapping("/admin/applications/{id}") Map<String,Object> detail(@PathVariable String id) { return applications.detail(id); }
    @PostMapping("/admin/applications/{id}/review") Map<String,Object> review(@PathVariable String id,@AuthenticationPrincipal AccountService.Account a,@Valid @RequestBody ApplicationService.Decision d) { return applications.review(id,a.id(),d); }
    @GetMapping("/admin/applications/{id}/documents/{side}") ResponseEntity<byte[]> document(@PathVariable String id,@PathVariable String side) {
        var doc=applications.document(id,side);
        return ResponseEntity.ok().header("Cache-Control","no-store").contentType(MediaType.parseMediaType((String)doc.get("mime_type")))
            .body(Base64.getDecoder().decode((String)doc.get("content_base64")));
    }
}
