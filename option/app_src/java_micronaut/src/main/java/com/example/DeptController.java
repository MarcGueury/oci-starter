package com.example;

import Dept;
import io.micronaut.http.HttpResponse;
import io.micronaut.http.annotation.Body;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Delete;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.Post;
import io.micronaut.http.annotation.Put;
import io.micronaut.scheduling.TaskExecutors;
import io.micronaut.scheduling.annotation.ExecuteOn;

import javax.persistence.PersistenceException;
import javax.validation.Valid;
import java.net.URI;
import java.util.List;

import static io.micronaut.http.HttpHeaders.LOCATION;

@ExecuteOn(TaskExecutors.IO)  
@Controller("/dept")  
class DeptController {

    private final GenreRepository genreRepository;


    private static final List<String> VALID_PROPERTY_NAMES = Arrays.asList("id", "name");
    private final EntityManager entityManager;  
    private final ApplicationConfiguration applicationConfiguration;

    public GenreRepositoryImpl(EntityManager entityManager, 
                               ApplicationConfiguration applicationConfiguration) {
        this.entityManager = entityManager;
        this.applicationConfiguration = applicationConfiguration;
    }

    @ReadOnly 
    public List<Dept> findAll() {
        String qlString = "SELECT d FROM Dept as d";
        TypedQuery<Dept> query = entityManager.createQuery(qlString, Dept.class);
        return query.getResultList();
    }


    DeptController(GenreRepository genreRepository) { 
        this.genreRepository = genreRepository;
    }

    @Get(value = "/dept") 
    List<Dept> list() {
        return findAll();
    }

}