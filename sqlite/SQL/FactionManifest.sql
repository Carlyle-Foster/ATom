CREATE TABLE "Factions" (
	"Name"	        TEXT NOT NULL UNIQUE,
	"PrimaryColor"	TEXT,
    "SecondaryColor"TEXT,
	PRIMARY KEY("Name")
);

INSERT INTO "Factions" (Name, PrimaryColor, SecondaryColor)
VALUES
("Delhi", "blue", "dark purple"),
("Rome", "purple", "gold"),
("Sparta", "black", "red");