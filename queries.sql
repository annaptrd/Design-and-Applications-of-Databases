# --------------------------------------
# --------------------------------------
DROP PROCEDURE IF EXISTS ValidateQuery;
DELIMITER //
CREATE PROCEDURE ValidateQuery(IN qNum INT, IN queryTableName VARCHAR(255))
BEGIN
	DECLARE cname VARCHAR(64);
	DECLARE done INT DEFAULT FALSE;
	DECLARE cur CURSOR FOR SELECT c.column_name FROM information_schema.columns c WHERE 
c.table_schema='movies' AND c.table_name=queryTableName;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

	# Add the column fingerprints into a tmp table
	DROP TABLE IF EXISTS cFps;
	CREATE TABLE cFps (
  	  `val` VARCHAR(50) NOT NULL
	) 
	ENGINE = InnoDB;

	OPEN cur;
	read_loop: LOOP
		FETCH cur INTO cname;
		IF done THEN
      			LEAVE read_loop;
    		END IF;
		
		DROP TABLE IF EXISTS ordered_column;
		SET @order_by_c = CONCAT('CREATE TABLE ordered_column as SELECT ', cname, ' FROM ', queryTableName, ' ORDER BY ', cname);
		PREPARE order_by_c_stmt FROM @order_by_c;
		EXECUTE order_by_c_stmt;
		
		SET @query = CONCAT('SELECT md5(group_concat(', cname, ', "")) FROM ordered_column INTO @cfp');
		PREPARE stmt FROM @query;
		EXECUTE stmt;

		INSERT INTO cFps values(@cfp);
		DROP TABLE IF EXISTS ordered_column;
	END LOOP;
	CLOSE cur;

	# Order fingerprints
	DROP TABLE IF EXISTS oCFps;
	SET @order_by = 'CREATE TABLE oCFps as SELECT val FROM cFps ORDER BY val'; 
	PREPARE order_by_stmt FROM @order_by;
	EXECUTE order_by_stmt;

	# Read the values of the result
	SET @q_yours = 'SELECT md5(group_concat(val, "")) FROM oCFps INTO @yours';
	PREPARE q_yours_stmt FROM @q_yours;
	EXECUTE q_yours_stmt;

	SET @q_fp = CONCAT('SELECT fp FROM fingerprints WHERE qnum=', qNum,' INTO @rfp');
	PREPARE q_fp_stmt FROM @q_fp;
	EXECUTE q_fp_stmt;

	SET @q_diagnosis = CONCAT('select IF(@rfp = @yours, "OK", "ERROR") into @diagnosis');
	PREPARE q_diagnosis_stmt FROM @q_diagnosis;
	EXECUTE q_diagnosis_stmt;

	INSERT INTO results values(qNum, @rfp, @yours, @diagnosis);

	DROP TABLE IF EXISTS cFps;
	DROP TABLE IF EXISTS oCFps;
END//
DELIMITER ;

# --------------------------------------

# Execute queries (Insert here your queries).

# Validate the queries
drop table if exists results;
CREATE TABLE results (
  `qnum` INTEGER  NOT NULL,
  `rfp` VARCHAR(50)  NOT NULL,
  `yours` VARCHAR(50)  NOT NULL,
  `diagnosis` VARCHAR(10)  NOT NULL
)
ENGINE = InnoDB;


# -------------
# Q1
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

select title
from movie
where movie_id in
	(select movie_id 
	from movie_has_genre 
	where genre_id in
		(select genre_id 
		from genre 
		where genre_name = 'Comedy')) 
and movie_id in 
	(select movie_id 
	from role
	where actor_id in 
		(select actor_id 
		from actor 
		where last_name= 'Allen')) ;
CALL ValidateQuery(1, 'q');
drop table if exists q;
# -------------


# -------------
# Q2
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

select d.last_name, title 
from director d, movie, role, actor, movie_has_genre, movie_has_director, movie_has_director md2
where (movie_has_director.movie_id = movie.movie_id 
	and d.director_id = movie_has_director.director_id 
		and movie_has_director.director_id = md2.director_id )
and (movie.movie_id = role.movie_id and role.actor_id = actor.actor_id and actor.last_name = "Allen")
and d.director_id in 
	(select director_id 
    from movie_has_director 
    where movie_id in 
		(select movie_id 
        from movie_has_genre 
        group by movie_id 
        having count(genre_id) >= 2))
group by last_name, title;

CALL ValidateQuery(2, 'q');
drop table if exists q;
# -------------


# -------------
# Q3
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

select a.last_name
from actor a 
where actor_id in
	(select actor_id 
	from role 
	where movie_id in
		(select movie_id 
		from movie_has_director 
		where director_id in
			(select director_id 
			from director d 
			where d.last_name=a.last_name)))
and  actor_id in
	(select actor_id 
	from role 
	where movie_id in
		(select movie_id 
		from movie_has_director 
		where director_id in
			(select director_id 
			from director i 
			where i.last_name<>a.last_name))
	and movie_id in
		(select movie_id 
		from movie_has_genre t1 
		where t1.genre_id in
			(select genre_id 
			from movie_has_genre m1 
			where m1.movie_id in
				(select movie_id 
				from movie_has_director 
				where director_id in
					(select director_id 
					from director d1 
					where d1.last_name=a.last_name)))));
CALL ValidateQuery(3, 'q');
drop table if exists q;
# -------------


# -------------
# Q4
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.
select 'yes' as answer
from genre g
where g.genre_name='Drama' and g.genre_id in
							(select genre_id 
							from movie_has_genre mg,movie m 
							where m.year=1995 and mg.movie_id=m.movie_id)
union 
select 'no' as answer
from genre 
where not exists(select g.genre_id 
				from genre g 
                where g.genre_name='Drama' and g.genre_id in #vazw select genre_id an kai den exei simasia ti tha kanei select
											(select genre_id 
											from movie_has_genre mg,movie m 
											where m.year=1995 and mg.movie_id=m.movie_id));

CALL ValidateQuery(4, 'q');
drop table if exists q;
# -------------


# -------------
# Q5
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

select a.last_name as director_1, b.last_name as director_2
from director a,director b,movie_has_director ma,movie_has_director mb,movie_has_genre ga,movie_has_genre gb
where (a.last_name<b.last_name and ma.director_id=a.director_id and mb.director_id=b.director_id and 
ma.movie_id=mb.movie_id and ga.movie_id=ma.movie_id and gb.movie_id=mb.movie_id and 
mb.movie_id in
			(SELECT movie_id
			from movie
			where (year>=2000 and year<=2006)))
group by a.last_name,b.last_name                                                                    
having (count(distinct ga.genre_id)>5 and count(distinct gb.genre_id)>5 ); 

CALL ValidateQuery(5, 'q');
drop table if exists q;
# -------------


# -------------
# Q6
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

select a.first_name,a.last_name,(select count(distinct m.director_id)
									from movie_has_director m
                                    where movie_id in
													(select movie_id 
													 from  role
                                                     where actor_id=a.actor_id)) as count
from actor a
where a.actor_id in(
					select r.actor_id 
                    from role r 
                    group by r.actor_id
                    having count(distinct movie_id)=3);

CALL ValidateQuery(6, 'q');
drop table if exists q;
# -------------


# -------------
# Q7
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

select distinct mg.genre_id,(select count(distinct m.director_id)
									from movie_has_director m
                                    where movie_id in
													(select movie_id 
													 from  movie_has_genre
                                                     where genre_id=mg.genre_id)) as count
from movie_has_genre mg
where mg.movie_id in(
					select m.movie_id 
					from movie_has_genre m 
					group by m.movie_id
					having count(m.movie_id)<2);

CALL ValidateQuery(7, 'q');
drop table if exists q;
# -------------


# -------------
# Q8
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

SELECT r.actor_id
FROM role r,genre,movie_has_genre m
WHERE r.movie_id=m.movie_id 
group by r.actor_id
having (count(distinct m.genre_id)=(select count(distinct genre_id) from genre));

CALL ValidateQuery(8, 'q');
drop table if exists q;
# -------------


# -------------
# Q9
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

select distinct a.genre_id as genre_id_1, b.genre_id as genre_id_2,
(select count(distinct da.director_id)
  from movie_has_director da,movie_has_director db
  where da.movie_id in(
                    select distinct movie_id
                    from movie_has_genre
                    where genre_id=a.genre_id)
  and db.movie_id in(
					select distinct movie_id
                    from movie_has_genre
					where genre_id=b.genre_id)
  and da.director_id=db.director_id) as count              
                                                                        
from movie_has_genre a,movie_has_genre b

where (a.genre_id<b.genre_id)
group by a.genre_id,b.genre_id
having (select count(distinct da.director_id)
		from movie_has_director da,movie_has_director db
          where da.movie_id in(
                               select distinct movie_id
							   from movie_has_genre
                               where genre_id=a.genre_id)
                               and db.movie_id in(
													select distinct movie_id
                                                    from movie_has_genre
                                                     where genre_id=b.genre_id)
and da.director_id=db.director_id)>0
order by a.genre_id,b.genre_id asc;


CALL ValidateQuery(9, 'q');
drop table if exists q;
# -------------


# -------------
# Q10
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

select g.genre_id as genre,a.actor_id as actor,
(select count(distinct r.movie_id)
from  role r 
where r.actor_id=a.actor_id and r.movie_id=mg.movie_id and mg.genre_id=g.genre_id) as count
from genre g,actor a,movie_has_genre mg
where not exists(select d.director_id
                 from movie_has_director d
                 where movie_id=mg.movie_id and d.director_id in
                                              (select director_id
                                               from movie_has_director md
                                               where md.movie_id in(select movie_id
                                                                  from movie_has_genre
                                                                  where genre_id<>g.genre_id and md.movie_id=movie_id)))
group by g.genre_id,a.actor_id,count
having count>0
order by g.genre_id,a.actor_id asc;                                                            
                                       

CALL ValidateQuery(10, 'q');
drop table if exists q;
# -------------

DROP PROCEDURE IF EXISTS RealValue;
DROP PROCEDURE IF EXISTS ValidateQuery;
DROP PROCEDURE IF EXISTS RunRealQueries;
