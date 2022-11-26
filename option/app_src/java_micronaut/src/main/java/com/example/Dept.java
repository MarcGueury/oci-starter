package com.example;

import javax.persistence.*;

@Entity
@Table(name = "dept")
public class Dept {

    @Id
    @Column(name = "deptno", nullable = false, updatable = false)
    private int deptno;

    @Basic(optional = false)
    @Column(name = "dname")
    private String dname;

    @Basic(optional = false)
    @Column(name = "loc")
    private String loc;

    public Dept() {
    }

    public int getDeptno() {
        return deptno;
    }

    public void setDeptno(int deptno) {
        this.deptno = deptno;
    }

    public String getDname() {
        return dname;
    }

    public void setDname(String dname) {
        this.dname = dname;
    }

    public String getLoc() {
        return loc;
    }

    public void setLoc(String loc) {
        this.loc = loc;
    }
}


