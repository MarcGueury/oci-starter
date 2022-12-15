package main
 
import (
    "fmt"
    "os"
    "net/http"
    "github.com/gin-gonic/gin"
)

type Dept struct {
    Deptno string `json:"deptno"`
    Dname string `json:"dname"`
    Loc string `json:"loc"`
}

func dept(c *gin.Context) {
    var static_depts = []Dept{
        Dept{Deptno: "10", Dname: "Asia", Loc: "Tokyo"},
        Dept{Deptno: "20", Dname: "Africa", Loc: "Lumbumbashi"},
        Dept{Deptno: "30", Dname: "Europe", Loc: "Brussels"},
        Dept{Deptno: "40", Dname: "America", Loc: "San-Francisco"},
    }     
    c.IndentedJSON(http.StatusOK, static_depts)
}

func info(c *gin.Context) {
    var s string =  "GoLang - No Database"
    c.Data(http.StatusOK, "text/html", []byte(s))
}

func main() {
    router := gin.Default()
    router.GET("/info", info)
    router.GET("/dept", dept)
    router.Run(":8080")
}
