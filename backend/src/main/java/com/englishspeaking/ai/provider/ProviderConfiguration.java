package com.englishspeaking.ai.provider;

import jakarta.persistence.*;

@Entity @Table(name="provider_configuration")
public class ProviderConfiguration {
    @Id @Column(length=10) public String channel;
    @Column(nullable=false,length=20) public String provider;
    @Column(nullable=false,length=100) public String model;
    @com.fasterxml.jackson.annotation.JsonIgnore
    @Column(nullable=false,length=8000) public String encryptedKey;
    @Version public Long revision;
}
