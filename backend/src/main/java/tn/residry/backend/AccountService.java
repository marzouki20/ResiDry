package tn.residry.backend;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.*;
import jakarta.validation.constraints.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AccountService implements ApplicationRunner {
    public record Account(String id, String name, String email, String role, String phone) {}
    public record Registration(@NotBlank @Size(max=150) String name, @Email @NotBlank @Size(max=254) String email,
        @Size(min=8,max=72) @NotNull String password, @NotNull String role, String phone) {
        @Override public String toString() { return "Registration[redacted]"; }
    }
    public record Login(@Email @NotBlank String email, @NotBlank String password) {
        @Override public String toString() { return "Login[redacted]"; }
    }
    public record Session(String token, Account account) {
        @Override public String toString() { return "Session[redacted]"; }
    }
    private final JdbcTemplate db;
    private final BCryptPasswordEncoder passwords = new BCryptPasswordEncoder(12);
    @Value("${residry.admin.email}") private String adminEmail;
    @Value("${residry.admin.password}") private String adminPassword;
    public AccountService(JdbcTemplate db) { this.db = db; }

    @Override public void run(ApplicationArguments args) {
        if (!adminEmail.isBlank() && !adminPassword.isBlank() &&
            db.queryForObject("SELECT COUNT(*) FROM accounts WHERE email=?", Integer.class, normalize(adminEmail)) == 0) {
            if (adminPassword.length() < 12) throw new IllegalStateException("Administrator password must contain at least 12 characters");
            insert(adminEmail, "Administrator", adminPassword, "ADMIN", null);
        }
    }
    private String normalize(String email) { return email.trim().toLowerCase(Locale.ROOT); }
    private Account insert(String email, String name, String password, String role, String phone) {
        var id = UUID.randomUUID().toString();
        db.update("INSERT INTO accounts VALUES (?,?,?,?,?,?,?)", id, name.trim(), normalize(email),
            passwords.encode(password), role, phone, Timestamp.from(Instant.now()));
        return new Account(id, name.trim(), normalize(email), role, phone);
    }
    @Transactional public Session register(Registration input) {
        if (!Set.of("DRIVER","RESIDENT","LAUNDRY").contains(input.role()))
            throw new ApiException(HttpStatus.FORBIDDEN, "role_not_allowed");
        if (input.role().equals("DRIVER") && (input.phone() == null || !input.phone().matches("^\\+216[234579][0-9]{7}$")))
            throw new ApiException(HttpStatus.BAD_REQUEST, "invalid_tunisian_phone");
        if (input.password().getBytes(StandardCharsets.UTF_8).length > 72) throw new IllegalArgumentException();
        if(db.queryForObject("SELECT COUNT(*) FROM accounts WHERE email=?",Integer.class,normalize(input.email()))>0)
            throw new ApiException(HttpStatus.CONFLICT,"email_already_registered");
        try { return session(insert(input.email(), input.name(), input.password(), input.role(), input.phone())); }
        catch(org.springframework.dao.DuplicateKeyException e) { throw new ApiException(HttpStatus.CONFLICT,"email_already_registered"); }
    }
    public Session login(Login input) {
        var rows = db.queryForList("SELECT * FROM accounts WHERE email=?", normalize(input.email()));
        if (rows.isEmpty() || !passwords.matches(input.password(), (String)rows.get(0).get("password_hash")))
            throw new ApiException(HttpStatus.UNAUTHORIZED, "invalid_credentials");
        var row = rows.get(0);
        return session(new Account((String)row.get("id"), (String)row.get("name"), (String)row.get("email"), (String)row.get("role"), (String)row.get("phone")));
    }
    private Session session(Account account) {
        byte[] bytes = new byte[32]; new SecureRandom().nextBytes(bytes);
        var token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        db.update("INSERT INTO auth_sessions VALUES (?,?,?)", hash(token), account.id(), Timestamp.from(Instant.now().plusSeconds(28800)));
        return new Session(token, account);
    }
    public Account authenticate(String token) {
        var rows = db.queryForList("SELECT a.* FROM accounts a JOIN auth_sessions s ON a.id=s.account_id WHERE s.token_hash=? AND s.expires_at>?",
            hash(token), Timestamp.from(Instant.now()));
        if (rows.isEmpty()) return null;
        var row = rows.get(0);
        return new Account((String)row.get("id"), (String)row.get("name"), (String)row.get("email"), (String)row.get("role"), (String)row.get("phone"));
    }
    public void logout(String token) { db.update("DELETE FROM auth_sessions WHERE token_hash=?", hash(token)); }
    static String hash(String token) {
        try { return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8))); }
        catch (Exception e) { throw new IllegalStateException(e); }
    }
}
