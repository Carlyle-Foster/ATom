CREATE TABLE "Units" (
	"Name"	        TEXT NOT NULL UNIQUE,
	"Texture"	    TEXT,
	"Strength"	    INTEGER,
	"Defense"	    INTEGER,
	"Stamina"		INTEGER,
	"MovementType"	TEXT,
	"Cost"          INTEGER,
	PRIMARY KEY("Name")
);

INSERT INTO "Units" (Name, Texture, Strength, Defense, Stamina, MovementType, Cost)
VALUES
("Valet", "Assets/Sprites/adude.png", 6, 10, 2, "land", 22),
("Galley", "Assets/Sprites/Galley.png", 6, 10, 4, "shoreline", 35);