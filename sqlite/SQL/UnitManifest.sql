CREATE TABLE "Units" (
	"Name"	        TEXT NOT NULL UNIQUE,
	"Texture"	    TEXT,
	"Strength"	    INTEGER,
	"Defense"	    INTEGER,
	"Cost"          INTEGER,
	PRIMARY KEY("Name")
);

INSERT INTO "Units" (Name, Texture, Strength, Defense, Cost)
VALUES
("valet", "Assets/Sprites/adude.png", 6, 10, 16),
("parking_pass", "Assets/Sprites/adude.png", 6, 10, 16);