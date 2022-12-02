package main
 
import (
    "fmt"
    "database/sql"
    "github.com/godror/godror"
    "log"
    "net/http"
    "encoding/json"
    "github.com/gorilla/mux"
)

type Dept struct {
    deptno string `json:"deptno"`
    dname string `json:"dname"`
    loc string `json:"loc"`
}

// let's declare a global Articles array
// that we can then populate in our main function
// to simulate a database
var depts []Dept


func dept(){
 
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
 
    var dept Dept
    for rows.Next() {
        rows.Scan(&dept)
        depts = append(depts, dept)
    }
    return depts, nil
}

func homePage(w http.ResponseWriter, r *http.Request){
    fmt.Fprintf(w, "Welcome to the HomePage!")
    fmt.Println("Endpoint Hit: homePage")
}

func returnAllArticles(w http.ResponseWriter, r *http.Request){
    fmt.Println("Endpoint Hit: returnAllArticles")
    json.NewEncoder(w).Encode(Articles)
}

// Existing code from above
func handleRequests() {
    // creates a new instance of a mux router
    myRouter := mux.NewRouter().StrictSlash(true)
    // replace http.HandleFunc with myRouter.HandleFunc
    myRouter.HandleFunc("/", homePage)
    myRouter.HandleFunc("/all", returnAllArticles)
    // finally, instead of passing in nil, we want
    // to pass in our newly created router as the second
    // argument
    log.Fatal(http.ListenAndServe(":10000", myRouter))
}

func main() {
    fmt.Println("Rest API v2.0 - Mux Routers")
    depts = []Dept{
        Dept{deptno: "10", dname: "Gorilla", loc: "Zimbabwe"},
        Dept{deptno: "20", dname: "Gorgonzola", loc: "Italy"},
    }
    handleRequests()
}



