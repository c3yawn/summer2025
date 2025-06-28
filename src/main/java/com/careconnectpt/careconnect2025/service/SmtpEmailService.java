package com.careconnectpt.careconnect2025.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

/**
 * SMTP-backed mailer.  Inject once and reuse everywhere.
 */
@Service
// @RequiredArgsConstructor
@Slf4j
public class SmtpEmailService implements EmailService {

	// @Autowired
    private final JavaMailSender mailSender;
    private final String from;


    
    public SmtpEmailService(
            JavaMailSender mailSender,
            @Value("${app.mail.from}") String from) {
        this.mailSender = mailSender;
        this.from = from;
    }

    /** Plain-text message (fire-and-forget). */
    @Async
    @Override
    public void sendTextMail(String to, String subject, String body) {
        try {
            var msg = new SimpleMailMessage();
            msg.setFrom(from);
            msg.setTo(to);
            msg.setSubject(subject);
            msg.setText(body);
            mailSender.send(msg);
//            log.debug("Plain mail sent to {}", to);
        } catch (MailException ex) {
//            log.error("Plain mail send failed to {}", to, ex);
            // Optionally re-throw or propagate a custom exception here
        }
    }

    /** HTML message (fire-and-forget). */
    @Async
    @Override
    public void sendHtmlMail(String to, String subject, String html) {
        try {
            MimeMessage mime = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mime, "UTF-8");
            helper.setFrom(from);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(html, true);   // true => HTML
            mailSender.send(mime);
//            log.debug("HTML mail sent to {}", to);
        } catch (MessagingException | MailException ex) {
//            log.error("HTML mail send failed to {}", to, ex);
        }
    }
}
