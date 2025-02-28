CREATE TABLE "Factions" (
	"Name"	        TEXT NOT NULL UNIQUE,
	"PrimaryColor"	TEXT,
    "SecondaryColor"TEXT,
	PRIMARY KEY("Name")
);

INSERT INTO "Factions" (Name, PrimaryColor, SecondaryColor)
VALUES
("Delhi", 0xb15cb6ff, 0x1b993aff),
("Rome", 0x832eb8ff, 0xbb8e3bff),
("Sparta", 0x301212ff, 0xc01515ff);