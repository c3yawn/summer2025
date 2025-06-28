package com.careconnectpt.careconnect2025.service;

import java.time.Instant;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import java.time.temporal.ChronoUnit;
import com.careconnectpt.careconnect2025.model.Address;
import com.careconnectpt.careconnect2025.dto.AddressDto;
import com.careconnectpt.careconnect2025.dto.CaregiverRegistration;
import com.careconnectpt.careconnect2025.dto.LoginRequest;
import com.careconnectpt.careconnect2025.dto.LoginResponse;
import com.careconnectpt.careconnect2025.dto.PatientRegistration;
import com.careconnectpt.careconnect2025.exception.AppException;
import com.careconnectpt.careconnect2025.exception.AuthenticationException;
import com.careconnectpt.careconnect2025.exception.RegistrationException;
import com.careconnectpt.careconnect2025.model.Caregiver;
import com.careconnectpt.careconnect2025.model.EmailVerificationToken;
import com.careconnectpt.careconnect2025.model.Patient;
import com.careconnectpt.careconnect2025.model.ProfessionalInfo;
import com.careconnectpt.careconnect2025.model.User;
import com.careconnectpt.careconnect2025.repository.CaregiverRepository;
import com.careconnectpt.careconnect2025.repository.EmailVerificationTokenRepo;
import com.careconnectpt.careconnect2025.repository.PatientRepository;
import com.careconnectpt.careconnect2025.repository.UserRepository;
import com.careconnectpt.careconnect2025.security.JwtTokenProvider;
import com.careconnectpt.careconnect2025.security.Role;
import com.careconnectpt.careconnect2025.dto.ProfessionalInfoDto;

@Service
public class AuthService {

    private final UserRepository users;
    private final PatientRepository patients;
    private final CaregiverRepository caregivers;
    private final PasswordEncoder encoder;
    private final JwtTokenProvider jwt;
    private final EmailVerificationTokenRepo tokens;
    private final EmailService emailService; 
    
    public AuthService(UserRepository users,
                       PatientRepository patients,
                       CaregiverRepository caregivers,
                       PasswordEncoder encoder,
                       JwtTokenProvider jwt,
                       EmailVerificationTokenRepo tokens,
                       EmailService emailService
                       ) {
        this.users = users;
        this.patients = patients;
        this.caregivers = caregivers;
        this.encoder = encoder;
        this.jwt = jwt;
        this.tokens = tokens; 
        this.emailService = emailService;
    }

    /** ───────────────────────────  LOGIN  ─────────────────────────── */
    public LoginResponse login(LoginRequest req) {
    User user = users.findByEmail(req.getEmail())
            .orElseThrow(() -> new AuthenticationException("Invalid credentials"));

    System.out.println("Raw: " + req.getPassword());
    System.out.println("Hash: " + user.getPassword());
    System.out.println("Match: " + encoder.matches(req.getPassword(), user.getPassword()));
    if (!encoder.matches(req.getPassword(), user.getPassword()))
        throw new AuthenticationException("Invalid credentials");

    return LoginResponse.builder()
            .id(user.getId())
            .email(user.getEmail())
            .role(user.getRole())
            .token(jwt.createToken(user.getEmail(), user.getRole()))
            .build();
    }

   public Patient registerPatient(PatientRegistration reg) {
   if (users.existsByEmail(reg.getEmail()))
        throw new RegistrationException("Email already registered");

    User user = User.builder()
            .email(reg.getEmail())
            .password(encoder.encode(reg.getPassword()))
            .role(Role.PATIENT)
            .build();

    Address addr = toAddress(reg.getAddress());

    Caregiver caregiver = null;
    if (reg.getCaregiverId() != null) {
        caregiver = caregivers.findById(reg.getCaregiverId())
                .orElseThrow(() -> new RegistrationException("Caregiver not found"));
    }

    Patient patient = Patient.builder()
            .firstName(reg.getFirstName())
            .lastName(reg.getLastName())
            .dob(reg.getDob())
            .email(reg.getEmail())
            .phone(reg.getPhone())
            .address(addr)
            .user(user)
            .caregiver(caregiver)
            .relationship(reg.getRelationship())
            .build();

    try {
        return patients.save(patient);
     } catch (Exception e) {
        throw new AppException(HttpStatus.INTERNAL_SERVER_ERROR,
                "Exception occurred while saving patient to the database");
     }
    }

    public Caregiver registerCaregiver(CaregiverRegistration reg) {
    if (users.existsByEmail(reg.getCredentials().getEmail()))
        throw new RegistrationException("Email already registered");

    User user = new User();
    user.setEmail(reg.getCredentials().getEmail());
    user.setPassword(encoder.encode(reg.getCredentials().getPassword()));
    user.setRole(Role.CAREGIVER);

    Address addr = toAddress(reg.getAddress());

    ProfessionalInfoDto profDto = reg.getProfessional();
    ProfessionalInfo prof = new ProfessionalInfo();
    prof.setLicenseNumber(profDto.getLicenseNumber());
    prof.setIssuingState(profDto.getIssuingState());
    prof.setYearsExperience(profDto.getYearsExperience());

    Caregiver cg = Caregiver.builder()
            .firstName(reg.getFirstName())
            .lastName(reg.getLastName())
            .dob(reg.getDob())
            .email(reg.getCredentials().getEmail())
            .phone(reg.getPhone())
            .professional(prof)
            .address(addr)
            .user(user)
            .build();

    try {
        return caregivers.save(cg);
    } catch (Exception e) {
        throw new AppException(HttpStatus.INTERNAL_SERVER_ERROR,
                "Exception occurred while saving caregiver to the database");
    }
}
        
//        String token = UUID.randomUUID().toString();
//        EmailVerificationToken vt = new EmailVerificationToken(
//                token, user, Instant.now().plus(24, ChronoUnit.HOURS));
//        tokens.save(vt);
//        
//        String frontEndUrl = "";
//        String confirmLink = frontEndUrl + "/verify-email?token=" + token;
//        emailService.sendTextMail(                    // Your existing mail service
//                user.getEmail(),
//                "Confirm your CareConnect account",
//                """
//                Welcome to CareConnect!
//                
//                Please click the link below to activate your account:
//                
//                %s
//                
//                This link is valid for 24 hours.
//                """.formatted(confirmLink)
//        );

    /** ───────────────────────  helper  ────────────────────────────── */
    private Address toAddress(AddressDto dto) {

        return Address.builder()
                .line1(dto.line1())
                .line2(dto.line2())
                .city(dto.city())
                .state(dto.state())
                .zip(dto.zip())
                .build();
    }

    public void logout(String token) {
        // In a stateless JWT-based system, logout is typically handled on the client side.
        // However, if we want to implement token invalidation, we can maintain a blacklist or use a cache.
        // This is a placeholder for future implementation if needed.
    }
}