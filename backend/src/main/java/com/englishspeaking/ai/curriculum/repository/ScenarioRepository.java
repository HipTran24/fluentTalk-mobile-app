package com.englishspeaking.ai.curriculum.repository;

import com.englishspeaking.ai.curriculum.model.Scenario;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ScenarioRepository extends JpaRepository<Scenario, UUID> {
 @Query("select s from Scenario s where (:q='' or lower(s.title) like concat('%',:q,'%')) and (:topic is null or s.topicId=:topic) and (:active is null or s.active=:active)")
 Page<Scenario> searchAdmin(@Param("q") String q,@Param("topic") UUID topic,@Param("active") Boolean active,Pageable page);


    @Query("SELECT s FROM Scenario s WHERE s.active = true " +
           "AND (:topicId IS NULL OR s.topicId = :topicId) " +
           "AND (:level IS NULL OR s.level = :level) " +
           "AND (:kw IS NULL OR LOWER(s.title) LIKE :kw OR LOWER(s.description) LIKE :kw " +
           "     OR LOWER(s.roleAi) LIKE :kw OR LOWER(s.roleUser) LIKE :kw)")
    Page<Scenario> findFiltered(
            @Param("topicId") UUID topicId,
            @Param("level") String level,
            @Param("kw") String kw,
            Pageable pageable
    );
}
