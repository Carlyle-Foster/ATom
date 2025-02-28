CREATE TABLE "Technology" (
    "Name"	        TEXT NOT NULL UNIQUE,
    "Unlocks"       TEXT,
	"Cost"			INTEGER,
	PRIMARY KEY("Name")
);

INSERT INTO Technology (Name, Unlocks, Cost)
VALUES
("Fancy Hotels", "Valet", 0),
("Sailing", "Galley", 15),
("metalworking", "Forge", 10);