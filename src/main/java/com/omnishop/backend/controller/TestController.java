package com.omnishop.backend.controller;



import com.omnishop.backend.entity.TestEntity;
import com.omnishop.backend.repository.TestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.*;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/test")
@RequiredArgsConstructor
@EnableCaching
public class TestController {

    private final TestRepository testRepository;

    // POST: Save to MySQL and cache result
    @PostMapping("/save")
    @CachePut(value = "testEntity", key = "#result.id")
    public TestEntity save(@RequestBody String message) {
        return testRepository.save(new TestEntity(null, message));
    }

    // GET: First time fetches from MySQL, then cached in Redis
    @GetMapping("/{id}")
    @Cacheable(value = "testEntity", key = "#id")
    public TestEntity getById(@PathVariable Long id) {
        System.out.println("⏳ Fetching from MySQL...");
        Optional<TestEntity> entity = testRepository.findById(id);
        return entity.orElse(null);
    }
}

