module app;

import std.stdio;
import std.experimental.logger: trace;

import gio.Application : GApplication = Application;
import gtk.Main;
import gtk.Application;

import appwindow;

class GtkDApp : Application {

public:
    this(){   
        ApplicationFlags flags = ApplicationFlags.FLAGS_NONE;
        super("org.gnome.projectname", flags);
        this.addOnActivate(&onAppActivate);
        this.window = null;
    }

private:

    AppWindow window;

    void onAppActivate(GApplication app){
        trace("Activate App Signal");
        if (!app.getIsRemote()){
            this.window = new AppWindow(this);
        }

        this.window.present();
    }
}		

void main(string[] args) {
    createMyDB();

    Main.init(args);
    auto app = new GtkDApp();
    app.run(args);
}  


void createMyDB(){
    import arsd.sqlite;
    import std.file;

    if ("file.db".exists) return;
    Sqlite db;
    try {
        db = new Sqlite("file.db");
    } catch (DatabaseException de){
        return;
    }
    string query = "
                CREATE TABLE User (
                    id		INTEGER PRIMARY KEY AUTOINCREMENT,
                    email	TEXT	NOT NULL,
                    name	TEXT	NOT NULL,
                    age		INT		NOT NULL,
                    gender	INT		NOT NULL
                );
                ";

    db.query(query);

    insertSomeData(db);

}

void insertSomeData(DB)(ref DB db){
    string[] sql = [
        "INSERT INTO User ( email, name, age, gender) VALUES ('foo1@bar.com', 'foo barson', 20, 0);",
        "INSERT INTO User ( email, name, age, gender) VALUES ('foo2@bar.com', 'Sheryl crow', 30, 1);",
        "INSERT INTO User ( email, name, age, gender) VALUES ('foo3@bar.com', 'Dan Patlansky', 30, 0);",
        "INSERT INTO User ( email, name, age, gender) VALUES ('foo4@bar.com', 'Asım Can Gündüz', 20, 0);",
        "INSERT INTO User ( email, name, age, gender) VALUES ('foo5@bar.com', 'Chris Rea', 20, 0);",
        "INSERT INTO User ( email, name, age, gender) VALUES ('foo6@bar.com', 'Stevei Ray Vaughan', 20, 0);",
        "INSERT INTO User ( email, name, age, gender) VALUES ('foo7@bar.com', 'Ayhan Sicimoğlu', 20, 0);",
        "INSERT INTO User ( email, name, age, gender) VALUES ('foo7@bar.com', 'Doğan Canku', 20, 0);",
        "INSERT INTO User ( email, name, age, gender) VALUES ('foo7@bar.com', 'İlter Kurcala', 20, 0);"
    ];

    foreach(s; sql)
        db.query(s);

    db.lastInsertId().writeln;

}