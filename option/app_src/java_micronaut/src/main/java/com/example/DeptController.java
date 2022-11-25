package com.example;

import io.micronaut.http.*;
import io.micronaut.http.annotation.*;
import io.micronaut.scheduling.TaskExecutors;
import io.micronaut.scheduling.annotation.ExecuteOn;
import javax.validation.Valid;
import java.net.URI;
import java.util.List;

import static io.micronaut.http.HttpHeaders.LOCATION;

@ExecuteOn(TaskExecutors.IO)  
@Controller("/dept")  
class DeptController {
    @Inject
    DeptRepository deptRepository;

    DeptController() { 
    }

    @Get(value = "/dept") 
    List<Dept> dept() {
        return deptRepository.find();
    }
}