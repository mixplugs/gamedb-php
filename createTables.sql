CREATE TYPE player_career AS ENUM ('Knight', 'Mage', 'Priest');

CREATE TABLE servers (
  id SERIAL,
  running boolean NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE players (
  id SERIAL,
  server_id integer NOT NULL,
  name varchar(60) NOT NULL,
  level smallint NOT NULL,
  health integer NOT NULL,
  career player_career NOT NULL,
  PRIMARY KEY (server_id, id)
);

ALTER TABLE players
  ADD CONSTRAINT fk_player_server
  FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE;

CREATE TABLE items (
  id SERIAL,
  name varchar(60) NOT NULL,
  value integer NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE holds (
  server_id integer NOT NULL,
  player_id integer NOT NULL,
  item_id integer NOT NULL,
  quantity integer NOT NULL,
  PRIMARY KEY (server_id, player_id, item_id)
);

ALTER TABLE holds
  ADD CONSTRAINT fk_hold_player
  FOREIGN KEY (server_id, player_id) REFERENCES players(server_id, id) ON DELETE CASCADE;

ALTER TABLE holds
  ADD CONSTRAINT fk_hold_item
  FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE;

GRANT ALL PRIVILEGES ON TABLE servers TO gamedbuser;
GRANT ALL PRIVILEGES ON TABLE players TO gamedbuser;
GRANT ALL PRIVILEGES ON TABLE items TO gamedbuser;
GRANT ALL PRIVILEGES ON TABLE holds TO gamedbuser;

GRANT ALL PRIVILEGES ON ALL sequences IN SCHEMA PUBLIC TO gamedbuser;

CREATE FUNCTION player_check() RETURNS trigger AS $player_check$
  BEGIN
    IF NEW.level IS NULL THEN
      RAISE EXCEPTION 'level cannot be null';
    END IF;

    IF NEW.level <= 0 THEN
      RAISE EXCEPTION '% cannot have a <=0 level', NEW.level;
    END IF;

    IF NEW.health IS NULL THEN
      RAISE EXCEPTION 'health cannot be null';
    END IF;

    IF NEW.health <= 0 THEN
      RAISE EXCEPTION '% cannot have a <=0 health', NEW.health;
    END IF;

    RETURN NEW;
  END;
$player_check$ LANGUAGE plpgsql;

CREATE TRIGGER player_check BEFORE INSERT OR UPDATE ON players
    FOR EACH ROW EXECUTE PROCEDURE player_check();

CREATE OR REPLACE FUNCTION add_item(m_server_id integer, m_plsyer_id integer, m_item_id integer, m_quantity integer) RETURNS boolean AS $$
  BEGIN
    IF m_quantity <=0 THEN
      RAISE EXCEPTION 'Quantity must greater than 0.';
    END IF;

    IF NOT EXISTS(SELECT * FROM items WHERE id = m_item_id) THEN
      RAISE EXCEPTION 'Item not exist.';
    END IF;

    IF EXISTS(SELECT * FROM holds WHERE m_server_id = server_id AND m_plsyer_id = player_id AND m_item_id = item_id) THEN
      UPDATE holds SET quantity = m_quantity + quantity WHERE m_server_id = server_id AND m_plsyer_id = player_id AND m_item_id = item_id;
    ELSE
      INSERT INTO holds(server_id, player_id, item_id, quantity) VALUES(m_server_id, m_plsyer_id, m_item_id, m_quantity);
    END IF;

    RETURN TRUE;
  END;
$$ LANGUAGE plpgsql;


COMMIT;