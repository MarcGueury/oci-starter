using System;
using System.Data;
using Microsoft.AspNetCore.Mvc;

namespace starter.Controllers;

public class DeptController : ControllerBase
{
    private readonly ILogger<DeptController> _logger;

    public DeptController(ILogger<DeptController> logger)
    {
        _logger = logger;
    }

    [Route("dept")]
    public IEnumerable<Dept> Get()
    {
        return new Dept[]
        {
            new Dept { deptno = "10", dname = "Asia", loc = "Tokyo" },
            new Dept { deptno = "20", dname = "Africa", loc = "Lubumbashi" },
            new Dept { deptno = "30", dname = "Europa", loc = "Brussels" },
            new Dept { deptno = "40", dname = "America", loc = "San Francisco" }
        };
    }

    [Route("info")]
    public String Info()
    {
        return ".NET / No Database";
    }
}
