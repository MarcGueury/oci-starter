package com.example.demo;

import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import java.sql.*;

import java.util.ArrayList;
import java.util.List;

@RestController

public class DemoController {
  private String dbUrl = null;

  @Autowired
  public DemoController(DbProperties properties) {
    String baseUrl = "" + properties.getUrl();
    String username = System.getenv("DB_USER");
    String password = System.getenv("DB_PASSWORD");
    if (baseUrl == null) {
      return;
    }

    if (baseUrl.indexOf("mysql") > 0) {
      this.dbUrl = baseUrl + "?user=" + username + "&password=" + password;
    } else if (baseUrl.indexOf("oracle") > 0) {
      this.dbUrl = baseUrl.replace("@", username + "/" + password + "@");
    }
    System.err.println(this.dbUrl);
  }

  @RequestMapping(value = "/dept", method = RequestMethod.GET, produces = { "application/json" })  
  public List<Dept> query() {
    List<Dept> depts = new ArrayList<Dept>();
    try {
      Connection conn = DriverManager.getConnection(this.dbUrl);
      Statement stmt = conn.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT * FROM dept");
      while (rs.next()) {
        depts.add(new Dept(rs.getInt(1), rs.getString(2), rs.getString(3) ));
      }
    } catch (SQLException e) {
      System.err.println(e.getMessage());
    }
    return depts;
  }

  @RequestMapping(value = "/static", method = RequestMethod.GET, produces = { "application/json" })  
  public List<Dept> listDept() {
    List<Dept> depts = new ArrayList<Dept>();
    depts.add(new Dept(1, "Marc", "aa" ));
    depts.add(new Dept(2, "Mika", "bb" ));
    depts.add(new Dept(3, "Ivan", "cc"));
    depts.add(new Dept(4, "Marta", "cc"));
    depts.add(new Dept(5, "John", "cc"));   
    depts.add(new Dept(6, "Badr", "cc"));
    depts.add(new Dept(7, "Fernando", "cc"));
    depts.add(new Dept(8, "Christophe", "cc"));    
    return depts;
}

}
