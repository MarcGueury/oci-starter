package main
 
import (
    "fmt"
    "database/sql"
    _ "github.com/godror/godror"
    "os"
    "net/http"
    "github.com/gin-gonic/gin"
)

type Dept struct {
    Deptno string `json:"deptno"`
    Dname string `json:"dname"`
    Loc string `json:"loc"`
}

var static_depts = []Dept{
    Dept{Deptno: "10", Dname: "Gorilla", Loc: "Zimbabwe"},
    Dept{Deptno: "20", Dname: "Gorgonzola", Loc: "Italy"},
} 

func dept(c *gin.Context) {
    db, err := sql.Open("godror", os.Getenv("DB_USER")+"/"+os.Getenv("DB_PASSWORD")+"@"+os.Getenv("DB_URL"))
    if err != nil {
        fmt.Println(err)
        return
    }
    defer db.Close()
     
    rows,err := db.Query("select deptno, dname, loc from dept")
    if err != nil {
        fmt.Println("Error running query")
        fmt.Println(err)
        return
    }
    defer rows.Close()
    fmt.Println(rows)

    var d []Dept
    for rows.Next() {
        var dept=new(Dept)
        rows.Scan(&dept.Deptno, &dept.Dname, &dept.Loc)   
        fmt.Println(dept.Deptno, dept.Dname, dept.Loc) 
        d = append(d, *dept)
    }
    c.IndentedJSON(http.StatusOK, d)
}

func info(c *gin.Context) {
    var s string =  "GoLang - Oracle"
    c.Data(http.StatusOK, "text/html", []byte(s))
}

func static(c *gin.Context) {
    c.IndentedJSON(http.StatusOK, static_depts)
}

func main() {
    router := gin.Default()
    router.GET("/info", info)
    router.GET("/static", static)
    router.GET("/dept", dept)
    router.Run("localhost:8080")
}
