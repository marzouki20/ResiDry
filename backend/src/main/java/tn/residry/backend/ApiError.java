package tn.residry.backend;

import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.dao.DataIntegrityViolationException;

class ApiException extends RuntimeException {
    final HttpStatus status;
    ApiException(HttpStatus status, String code) { super(code); this.status = status; }
}

@RestControllerAdvice
public class ApiError {
    @ExceptionHandler(ApiException.class)
    ResponseEntity<?> api(ApiException e) { return ResponseEntity.status(e.status).body(Map.of("error", e.getMessage())); }
    @ExceptionHandler({MethodArgumentNotValidException.class, IllegalArgumentException.class})
    ResponseEntity<?> invalid(Exception e) { return ResponseEntity.badRequest().body(Map.of("error", "invalid_request")); }
    @ExceptionHandler(DataIntegrityViolationException.class)
    ResponseEntity<?> duplicate(Exception e) { return ResponseEntity.status(409).body(Map.of("error", "conflict")); }
}
