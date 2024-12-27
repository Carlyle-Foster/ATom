CREATE TABLE "Units" (
	"Name"	        TEXT NOT NULL UNIQUE,
	"Texture"	    TEXT,
	"Strength"	    INTEGER,
	"Defense"	    INTEGER,
	"MovementType"	TEXT,
	"Cost"          INTEGER,
	PRIMARY KEY("Name")
);

INSERT INTO "Units" (Name, Texture, Strength, Defense, MovementType, Cost)
VALUES
("Valet", "Assets/Sprites/adude.png", 6, 10, "land", 16),
("Galley", "Assets/Sprites/Galley.png", 6, 10, "shoreline", 16);