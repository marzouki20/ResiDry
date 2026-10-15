package tn.residry.backend;

import java.io.IOException;
import java.util.List;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.context.annotation.*;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.filter.OncePerRequestFilter;

@Configuration
public class SecurityConfiguration {
    @Bean SecurityFilterChain security(HttpSecurity http, AccountService accounts) throws Exception {
        http.csrf(c -> c.disable()).sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(a -> a.requestMatchers("/api/auth/register", "/api/auth/login", "/api/health").permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .requestMatchers("/api/driver/**").hasRole("DRIVER").anyRequest().authenticated())
            .exceptionHandling(e -> e.authenticationEntryPoint((req,res,ex) -> {res.setStatus(401);res.setContentType("application/json");res.getWriter().write("{\"error\":\"unauthorized\"}");})
                .accessDeniedHandler((req,res,ex) -> {res.setStatus(403);res.setContentType("application/json");res.getWriter().write("{\"error\":\"forbidden\"}");}))
            .addFilterBefore(new OncePerRequestFilter() {
                @Override protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
                    throws ServletException, IOException {
                    var auth = req.getHeader("Authorization");
                    if (auth != null && auth.startsWith("Bearer ")) {
                        var account = accounts.authenticate(auth.substring(7));
                        if (account != null) SecurityContextHolder.getContext().setAuthentication(
                            new UsernamePasswordAuthenticationToken(account, null, List.of(new SimpleGrantedAuthority("ROLE_"+account.role()))));
                    }
                    chain.doFilter(req,res);
                }
            }, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}
