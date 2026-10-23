package com.englishspeaking.ai.profile.infrastructure;

import com.englishspeaking.ai.profile.domain.Profile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ProfileRepository extends JpaRepository<Profile, UUID> {
 @org.springframework.data.jpa.repository.Query("select p from Profile p where (:q='' or lower(p.displayName) like concat('%',:q,'%') or lower(p.email) like concat('%',:q,'%')) and (:level='' or p.level=:level)")
 org.springframework.data.domain.Page<Profile> searchAdmin(@org.springframework.data.repository.query.Param("q") String q,@org.springframework.data.repository.query.Param("level") String level,org.springframework.data.domain.Pageable page);
}
