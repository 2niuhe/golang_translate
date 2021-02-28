package main

import (
	"database/sql"
	"flag"
	"fmt"
	"os"

	"github.com/fatih/color"
	_ "github.com/mattn/go-sqlite3" // Import go-sqlite3 library
)

// 实际中应该用更好的变量名
var (
	h bool
	d bool
)

func init() {
	flag.BoolVar(&h, "h", false, "show help")
	flag.BoolVar(&d, "d", false, "output include word definition")

	// 改变默认的 Usage
	flag.Usage = usage
}

func main() {

	flag.Parse()

	if h || flag.NArg() == 0 {
		flag.Usage()
	}
	for i := 0; i != flag.NArg(); i++ {
		if i > 0 {
			color.Yellow("=====================")
		}
		dbquery(flag.Arg(i))

	}
}

func usage() {
	fmt.Fprintf(os.Stderr, `golang trans: trans/0.0.1
Usage: Translate english word to chinese.

Options:
`)
	flag.PrintDefaults()
}

func dbquery(word string) {
	sqliteDatabase, _ := sql.Open("sqlite3", "./assets/ultimate.db") // Open the created SQLite File
	defer sqliteDatabase.Close()                                     // Defer Closing the database

	// DISPLAY INSERTED RECORDS
	queryByWord(sqliteDatabase, word)
}

func queryByWord(db *sql.DB, word string) {

	var phonetic string
	var translation string
	var definition string
	var exchange string

	if d {
		stmt, err := db.Prepare("select phonetic, translation,  exchange,  definition from stardict where word = ?")
		defer stmt.Close()
		if err != nil {
			fmt.Print(err)
		}
		err = stmt.QueryRow(word).Scan(&phonetic, &translation, &exchange, &definition)
	} else {
		stmt, err := db.Prepare("select phonetic, translation, exchange from stardict where word = ?")
		defer stmt.Close()
		if err != nil {
			fmt.Print(err)
		}
		err = stmt.QueryRow(word).Scan(&phonetic, &translation, &exchange)
	}

	color.HiBlue("音标: %s", phonetic)

	color.Blue(translation)
	if len(exchange) > 0 {
		color.Yellow("----------------------")
		color.Blue(exchange)
	}
	if d {
		color.Yellow("----------------------")
		color.Blue(definition)
	}

}
