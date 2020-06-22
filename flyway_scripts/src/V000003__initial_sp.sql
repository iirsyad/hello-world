DELIMITER $$
CREATE  PROCEDURE `AddBenchmarkCompetitorBrands`(
															 IN pBenchmarkId INT, 
                                                             IN pBenchmarkSessionId INT,
                                                             IN pBenchmarkConfig json)
BEGIN
	    
	UPDATE BenchmarkCompetitorBrands
    SET is_active = 0,
        modified_date = NOW()
    WHERE benchmark_id = pBenchmarkId;
        
	INSERT INTO BenchmarkCompetitorBrands (benchmark_id, benchmark_session_id, brand_id)
	SELECT pBenchmarkId, pBenchmarkSessionId , y.id as brandId
	FROM 
	(
		SELECT 
		JSON_EXTRACT(pBenchmarkConfig, CONCAT('$[', B._row, ']', '.brandId')) as brandId
		FROM (SELECT pBenchmarkConfig AS B) AS A
		INNER JOIN t_list_row AS B ON B._row < JSON_LENGTH(pBenchmarkConfig) 
	) x
	JOIN Brand y
		on x.brandId = y.brand_key;


END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `AddBlobSourceMetadata`( 
                                                             IN pSourceType VARCHAR(128),
                                                             IN pSourceHandle VARCHAR(128),
                                                             IN pBlobInfo json)
BEGIN
	
    set @dt = now();

	set @blob_uri = JSON_UNQUOTE(JSON_EXTRACT(pBlobInfo,'$.BlobUri'));
	set @blob_size = JSON_EXTRACT(pBlobInfo,'$.BlobSize');
    set @blob_ts = JSON_UNQUOTE(JSON_EXTRACT(pBlobInfo,'$.BlobTimestamp'));
    
    
    set @source_id = ( 	SELECT a.id
						from ContentSource a
						JOIN ChannelType b
							on a.channel_type_id = b.id
						WHERE handle_id = pSourceHandle and  b.name = pSourceType); 
    
	INSERT INTO ContentBlobMetaInfo
		(content_source_id, blob_uri, blob_size, max_blob_timestamp)
	VALUES
		(@source_id, @blob_uri, @blob_size, @blob_ts);
        
    set @content_blob_id = ( SELECT LAST_INSERT_ID());
    
	select @source_id as source_id, @content_blob_id  as content_blob_id;
    

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `AddBrandSetupRequest`(IN pBrandId INT, IN pPriority  tinyint)
BEGIN
	set @dt = now();
    
    set @cnt = (SELECT count(*)
			FROM BrandSetupRequest
			WHERE brand_id = pBrandId and datediff(@dt, create_date  ) <= 1 and status_id in (1,2,3));
	
	if @cnt < 1 then
		INSERT INTO BrandSetupRequest
        ( brand_id, priority)
        VALUES
        (
			pBrandId, pPriority
        );
    end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `AddBrandToUser`(IN pUserId VARCHAR(64), 
															 IN pBrandKey VARCHAR(64))
BEGIN
	
    set @dt = now();
    
    set @brand_id = ( SELECT Id 
					  FROM Brand
					  WHERE brand_key = pBrandKey and is_active = 1);
                              
	set @user_id = (SELECT id 
					FROM User 
                    WHERE is_active = 1 and auth0UserId = pUserId);

	set @userBrandId = (SELECT Id 
						FROM UserBrand
						WHERE user_id = @user_id  and brand_id = @brand_id AND is_active = 1);

	IF @userBrandId is  null THEN
        insert into UserBrand
        (
			user_id, brand_id
        )
        VALUES
        (
			@user_id ,  @brand_id
        );
		set @userBrandId = ( SELECT LAST_INSERT_ID());
	end if;
    
	UPDATE BrandSession a
    JOIN Brand b
		ON a.brand_id = b.id AND b.brand_key = pBrandKey
    SET 
        a.run_status_id = 10,
		a.modified_date =  NOW()
	WHERE a.session_key = pBrandKey; 
    
    -- select @userBrandId as userBrandId;

    select d.brand_id, 
			b.brand_key, 
            b.brand_name, 
            b.create_date as brand_create_date, 
            b.last_refresh_date as brand_refresh_date, 
            b.config_json as brand_config,  
            d.create_date as session_create_date, 
            d.modified_date as session_refresh_date,
            d.session_key,
			d.run_status_id as brand_status_id,
            l.brand_logo_url,
            z.is_active
    from 
    (
		select c.id as brand_id, max(d.id) as session_id, a.is_active
		from UserBrand a
		join Brand c
			on a.brand_id = c.id and a.id = @userBrandId
		join BrandSession d
			on c.id = d.brand_id
		group by c.id , a.is_active
    ) z
    JOIN Brand b
		on z.brand_id = b.id and b.id = @brand_id
		
    JOIN BrandSession d
		on b.id = d.brand_id and  d.id = z.session_id
        
	LEFT JOIN BrandLogo l
		on b.id = l.brand_id;
        
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `AddNewBenchmark`(IN pUserId VARCHAR(64),
															 IN pBrandKey VARCHAR(64), 
                                                             IN pBenchmarkConfig json)
BEGIN
	
	set @benchmark_name = JSON_UNQUOTE(JSON_EXTRACT(pBenchmarkConfig,'$.BenchmarkName'));
    set @freq = JSON_UNQUOTE(JSON_EXTRACT(pBenchmarkConfig,'$.Frequency'));
	set @benchmark_cfg = JSON_EXTRACT(pBenchmarkConfig,'$.BenchmarkConfig');
  
	set @brand_id = (select id from Brand where brand_key = pBrandKey );
    set @freq_id = (select id from ScheduleFrequency where name = @freq);
    
    set @benchmark_key = (SELECT UUID());
    
    set @user_id = ( 	SELECT id
						from User
						WHERE auth0UserId = pUserId); 
                        
	INSERT INTO Benchmark
    (
		config_json, benchmark_key, name, frequency_Id
    )
    VALUES
    (
		@benchmark_cfg, @benchmark_key, @benchmark_name, @freq_id
    );
    
    set @benchmark_id = ( SELECT LAST_INSERT_ID());
    
    INSERT INTO BrandBenchmark
    (
		brand_id, benchmark_id
    )
    VALUES
    (
		 @brand_id, @benchmark_id
    );
    
    SELECT @brand_id as brand_id, pBrandKey as brand_key, @benchmark_id as benchmark_id,  @benchmark_key as benchmark_key;

 
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `AddNewBenchmarkSession`(IN pUserId VARCHAR(64),
															 IN pBenchmarkId INT, 
                                                             IN pBenchmarkConfig json)
BEGIN
	    
    set @benchmark_session_key = (SELECT UUID());

                        
	INSERT INTO BenchmarkSession
    (
		 benchmark_id, benchmark_session_key,  config_json
    )
    VALUES
    (
		pBenchmarkId, @benchmark_session_key, pBenchmarkConfig
    );
    
    set @benchmark_session_id = ( SELECT LAST_INSERT_ID());
    
	UPDATE Benchmark
	SET config_json = pBenchmarkConfig
	WHERE id = pBenchmarkId;
    
    CALL AddBenchmarkCompetitorBrands(pBenchmarkId, @benchmark_session_id, pBenchmarkConfig);
    
    SELECT @benchmark_session_id as benchmark_session_id,  @benchmark_session_key as benchmark_session_key;

 
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `AddNewBrandSessionTask`(IN pBrandId INT, 
															 IN pBrandSessionId INT, 
															 IN pSourceId INT, 
                                                             IN pBlobId INT)
BEGIN
	set @taskId = ( select Id 
					FROM BrandSessionTask 
					WHERE brand_session_id = pBrandSessionId AND
						  content_source_id = pSourceId );
                          
                          
    IF @taskId is  null then                      
		INSERT INTO BrandSessionTask
		( brand_session_id, content_source_id, content_blob_id, status_id)
		VALUES
		( pBrandSessionId, pSourceId, pBlobId, 1);
	end if;
    
    

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `AddNewContentSource`( 
                                                             IN pSourceHandle VARCHAR(128),
                                                             IN pSourceType VARCHAR(128),
                                                             OUT pSourceId int)
BEGIN
	
	set@src_type_id = (select Id from ChannelType where name = pSourceType );
    
	set @src_id = ( SELECT a.id
					from ContentSource a
					JOIN ChannelType b
						on a.channel_type_id = b.id
					WHERE a.handle_id = pSourceHandle and  b.id = @src_type_id );
    
     if @src_id is null then
		INSERT INTO ContentSource
			(channel_type_id, handle_id)
		VALUES
			(@src_type_id, pSourceHandle);
            
            set @src_id = (select LAST_INSERT_ID());
    end if;
    
    SET pSourceId := @src_id;
     

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `AddNewContentSource2`( 
                                                             IN pSourceHandle VARCHAR(128),
                                                             IN pSourceType VARCHAR(128),
                                                             OUT pSourceId int)
BEGIN
	
	set@src_type_id = (select Id from ChannelType where name = pSourceType );
    
	set @src_id = ( SELECT a.id
					from ContentSource a
					JOIN ChannelType b
						on a.channel_type_id = b.id
					WHERE a.handle_id = pSourceHandle and  b.id = @src_type_id );
    
     if @src_id is null then
		INSERT INTO ContentSource
			(channel_type_id, handle_id)
		VALUES
			(@src_type_id, pSourceHandle);
            
            set @src_id = (select LAST_INSERT_ID());
    end if;
    
    SET pSourceId := @src_id;
     
	select @src_id;
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `AddNewPayment`(IN pPaymentMethodId VARCHAR(64),
															 IN pUserId VARCHAR(128), 
                                                             IN pCustomerId VARCHAR(64))
BEGIN

	SET @UserId = ( SELECT id FROM User
					WHERE auth0UserId = pUserId);

	INSERT INTO Payment
    (
		paymentMethodId, user_id, customerId
    )
    VALUES
    (
		pPaymentMethodId, @UserId, pCustomerId
    );
    
    
    SELECT paymentMethodId, @UserId, customerId from Payment;

 
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `AddNewSessionToExistingBrand`(IN pUserId VARCHAR(64), 
															 IN pBrandId INT, 
															 IN pBrandSessionKey VARCHAR(64), 
                                                             IN pBrandSessionConfig json)
BEGIN
	
    set @dt = now();
    
    set @brand_session_id = ( SELECT Id 
							  FROM BrandSession
							  WHERE brand_id = pBrandId AND session_key = pBrandSessionKey);

	IF @brand_session_id IS NULL THEN
		INSERT INTO BrandSession
		(
			session_key, brand_id, run_status_id, config_json
		)
		VALUES
		(
			pBrandSessionKey, pBrandId, 1, pBrandSessionConfig
		);
    
		set @brand_session_id = ( SELECT LAST_INSERT_ID());
	else
		UPDATE BrandSession
        SET modified_date = @dt,
			config_json = pBrandSessionConfig
		WHERE id = @brand_session_id;
	end if;
    
	UPDATE Brand
    SET last_refresh_date = @dt
    WHERE id = pBrandId;
    
    IF pUserId is not null and LENGTH(pUserId) > 0 then
    
		set @user_id = (select id from User where auth0UserId = pUserId );
        
        insert into UserBrand
        (
			user_id, brand_id
        )
        VALUES
        (
			@user_id ,  pBrandId
        );
    
    end if;
    
	select pBrandId as brand_id , @brand_session_id as brand_session_id;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `AddNewSessionToExistingBrand2`(IN pUserId VARCHAR(64), 
															 IN pBrandKey VARCHAR(64), 
															 IN pBrandSessionKey VARCHAR(64), 
                                                             IN pBrandSessionConfig json)
BEGIN
	
    set @dt = now();
    
    set @brand__id = ( SELECT Id 
					  FROM Brand
					  WHERE brand_key = pBrandKey);    
    
    set @brand_session_id = ( SELECT Id 
							  FROM BrandSession
							  WHERE brand_id = @brand__id AND session_key = pBrandSessionKey);

	IF @brand_session_id IS NULL THEN
		INSERT INTO BrandSession
		(
			session_key, brand_id, run_status_id, config_json
		)
		VALUES
		(
			pBrandSessionKey, @brand__id, 1, pBrandSessionConfig
		);
    
		set @brand_session_id = ( SELECT LAST_INSERT_ID());
	else
		UPDATE BrandSession
        SET modified_date = @dt,
			config_json = pBrandSessionConfig
		WHERE id = @brand_session_id;
	end if;
    
	UPDATE Brand
    SET last_refresh_date = @dt
    WHERE id = @brand__id;
    
	select @brand__id as brand_id , @brand_session_id as brand_session_id;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `AddUserFeedback`( IN pUserId VARCHAR(45), IN pUserEmail VARCHAR(255), IN pFeedback VARCHAR(1024))
BEGIN
	INSERT INTO UserFeedback
    (
		 userId, email, feedback
    )
    VALUES
    (
		pUserId, pUserEmail, pFeedback
    );
    	
	commit;
    
    SELECT * FROM UserFeedback
	WHERE userId = pUserId and email = pUserEmail;
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `AddUserMessage`( IN pUserId VARCHAR(128), IN pMessage VARCHAR(255), IN pCat SMALLINT(4))
BEGIN
	INSERT INTO Message
    (
		 msg_content, cat_id,  deleted
    )
    VALUES
    (
		pMessage, pCat, 0
    );
    
    set @messageId= ( SELECT LAST_INSERT_ID());
    
    INSERT INTO UserMessage
    (
		user_id, msg_id
    )
    VALUES
    (
		pUserId, @messageId
    );
	
    SELECT * FROM UserMessage
	WHERE user_id = pUserId and msg_id = @messageId;
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `CopyBrand`(IN pUser_key NVARCHAR(128), IN pBrand_key NVARCHAR(64))
cpBlock: BEGIN

	SET @user_id = (SELECT id FROM User WHERE auth0UserId = pUser_key); 
        
    IF @user_id IS NULL THEN
		SIGNAL SQLSTATE '42927' SET MESSAGE_TEXT = 'User not found';
    END IF;
    
    SET @brandCount =  ( SELECT count(*)
						FROM UserBrand a
						JOIN Brand b
							on a.brand_id = b.id AND a.user_id = @user_id
						WHERE b.brand_key = pBrand_key) ;
	IF @brandCount > 0 THEN
		LEAVE cpBlock;
    END IF;
    
	-- first create a copy of target brand
	SET @new_key = (SELECT UUID());
    
	INSERT INTO Brand
	(	brand_name, 
		brand_key, 
        frequency_id, 
        config_json, 
        origin_id, 
        last_refresh_date, 
        create_date, 
        modified_date,
        is_active, 
        description)
	
	SELECT 	a.brand_name, 
			@new_key, 
            a.frequency_id, 
            a.config_json, 
            a.origin_id, 
            a.last_refresh_date, 
            a.create_date, 
            a.modified_date, 
            1, 
            a.description
	FROM Brand a
	WHERE a.brand_key = pBrand_key;
    
    SET @new_id = ( SELECT LAST_INSERT_ID());
    
    -- now copy brandsession from target brand
    -- first create a temp table
    CREATE TEMPORARY TABLE IF NOT EXISTS tbl_brand_session_temporary
    (
			brand_id int, 
            brand_key varchar(64), 
            new_brand_id int,
            new_brand_key  varchar(64), 
            brand_logo_url varchar(1024),
            session_id int, 
            session_key varchar(64), 
            new_session_id int null,
            new_session_key varchar(64) null, 
            run_status_id int,
            session_create_date datetime, 
            session_modified_date datetime null,
            session_config_json json,
            result_type_id smallint,
            result_json json, 
            result_create_date datetime, 
            result_modified_date datetime null
    );

   -- insert data into temp table for all sessions for that target brand
	INSERT INTO tbl_brand_session_temporary
    (
			brand_id, 
            brand_key, 
            new_brand_id,
            new_brand_key,
            brand_logo_url,
            session_id, 
            session_key, 
            new_session_id,
            new_session_key, 
            run_status_id,
            session_create_date, 
            session_modified_date,
            session_config_json,
            result_type_id,
            result_json, 
            result_create_date, 
            result_modified_date   
    )
    
	SELECT a.id as brand_id, 
            a.brand_key, 
            @new_id,
            @new_key,
            l.brand_logo_url,
            b.id as session_id, 
            b.session_key, 
            -1 as new_session_id,
            UUID() as new_session_key,
            b.run_status_id,
            b.create_date as session_create_date, 
            b.modified_date as session_modified_date,
            b.config_json,
            c.result_type_id,
            c.result_json, 
            c.create_date as session_create_date, 
            c.modified_date as session_modified_date
	FROM ( SELECT id, brand_key
		   FROM Brand 
           WHERE brand_key = pBrand_key) a
	JOIN BrandSession b
		ON a.id = b.brand_id
	JOIN BrandSessionResult c
		ON b.id = c.brand_session_id
	JOIN ResultType d
		ON c.result_type_id = d.id
	LEFT JOIN BrandLogo l
		ON a.id = l.brand_id
	WHERE b.run_status_id IN (3,4, 10);
    
 
	-- create copy of the sessions for target brand from temp table
    
	INSERT INTO BrandSession
	(
		session_key, 
        brand_id, 
        run_status_id, 
        config_json, 
        create_date, 
        modified_date
	)
    SELECT new_session_key,
			new_brand_id,
            run_status_id,
            session_config_json,
			session_create_date, 
            session_modified_date
    FROM tbl_brand_session_temporary;
    
    -- now get the id of the new session records and update the temp table
    UPDATE tbl_brand_session_temporary a
	JOIN BrandSession b
		ON  a.new_session_key = b.session_key
	SET a.new_session_id = b.id
    WHERE a.new_session_id < 0;
            
    -- now copy new records to session results using new ids
	INSERT INTO BrandSessionResult
	(
		brand_session_id, 
        result_type_id, 
        result_json, 
        create_date, 
        modified_date,
        is_active
	)	
    SELECT new_session_id,
            result_type_id,
            result_json, 
            result_create_date, 
            result_modified_date,
            1
    FROM tbl_brand_session_temporary;    
    
    -- now copy the session task
 	INSERT INTO BrandSessionTask
	(
		brand_session_id, 
        content_source_id, 
        content_blob_id, 
        status_id, 
        start_date,
        end_date
	)  
    SELECT a.new_session_id,
			b.content_source_id,
			b.content_blob_id, 
			b.status_id, 
			b.start_date,
			b.end_date
    FROM tbl_brand_session_temporary a
    JOIN BrandSessionTask b
		ON a.session_id = b.brand_session_id;
        
        
    -- copy brand logo    
  	INSERT INTO BrandLogo
	(
		brand_id, 
        brand_logo_url
	) 
    SELECT DISTINCT new_brand_id, 
					brand_logo_url
    FROM tbl_brand_session_temporary LIMIT 1;
    
    -- now Brand Archetype Goal
    INSERT INTO BrandArchetypeGoal
	(
		brand_id,
		archetype_target,
		score_json,
		create_date,
		modified_date
	)

	SELECT @new_id,
			archetype_target,
			score_json,
			create_date,
			modified_date
	FROM ( SELECT id 
			FROM Brand WHERE brand_key = pBrand_key ) a
	JOIN BrandArchetypeGoal b
		ON a.id = b.brand_id;
    
 
 
	-- now copy benchmark
    -- first create a temp table for holding benchmark associated with the owner brand
    CREATE TEMPORARY TABLE IF NOT EXISTS tbl_brand_benchmark_temporary
    (
			brand_owner_id int, 
            brand_owner_key varchar(64), 
            new_brand_owner_id int,
            new_brand_owner_key  varchar(64), 
            benchmark_id int, 
            benchmark_key varchar(64), 
            new_benchmark_id int null,
            new_benchmark_key varchar(64) null, 
            benchmark_name varchar(128) null,
            benchmark_config json,
            benchmark_frequency_id int, 
            benchmark_create_date datetime null,
            benchmark_modified_date datetime null,
            benchmark_is_active bit,
            benchmark_status_id tinyint
    );
    
	CREATE TEMPORARY TABLE IF NOT EXISTS tbl_brand_benchmark_session_temporary
    (
            benchmark_id int, 
            benchmark_key varchar(64), 
            session_id int,
            session_key varchar(64),
            new_benchmark_id int null,
            new_benchmark_key varchar(64) null, 
            new_session_id int,
            new_session_key varchar(64),
            config_json json,
			score_json json null,
			status_id tinyint null,
			create_date datetime ,
			modified_date datetime,
			is_active bit 
    );
    
    
    INSERT INTO tbl_brand_benchmark_temporary
    (
 			brand_owner_id, 
            brand_owner_key, 
            new_brand_owner_id,
            new_brand_owner_key, 
            benchmark_id, 
            benchmark_key, 
            new_benchmark_id,
            new_benchmark_key, 
            benchmark_name,
            benchmark_config,
            benchmark_frequency_id, 
            benchmark_create_date,
            benchmark_modified_date,
            benchmark_is_active,
            benchmark_status_id   
    )
	SELECT a.id as brand_owner_id,
			a.brand_key as brand_owner_key,
			@new_id as new_brand_owner_id,
			@new_key as new_brand_owner_key,
			c.id as benchmark_id,
			c.benchmark_key as benchmark_key,
			-1 as new_benchmark_id,
			uuid() as new_benchmark_key,
			c.name as benchmark_name,
            c.config_json as benchmark_config,
			c.frequency_id as benchmark_frequency_id,
			c.create_date as benchmark_create_date,
			c.modified_date as benchmark_modified_date,
			1 as benchmark_is_active,
			c.status_id as benchmark_status_id
			
	FROM (  SELECT id, brand_key 
			FROM Brand 
			WHERE brand_key = pBrand_key ) a
	JOIN BrandBenchmark b
		ON a.id = b.brand_id and b.is_active = 1
	JOIN Benchmark c
		ON c.id = b.benchmark_id;
        
	
    -- now create new benchmark records
    INSERT INTO Benchmark(
		benchmark_key,
        name,
		config_json,
		frequency_id,
		create_date,
		modified_date,
		is_active,
		status_id    
    )
    SELECT  new_benchmark_key, 
            benchmark_name,
            benchmark_config,
            benchmark_frequency_id, 
            benchmark_create_date,
            benchmark_modified_date,
            benchmark_is_active,
            benchmark_status_id  			
    FROM tbl_brand_benchmark_temporary;
        

    -- now get the id of the new benchmark records and update the temp table
    UPDATE tbl_brand_benchmark_temporary a
	JOIN Benchmark b
		ON  a.new_benchmark_key = b.benchmark_key
	SET a.new_benchmark_id = b.id
    WHERE a.new_benchmark_id < 0;	
    
    -- next, copy the BenchmarkSession
	INSERT INTO tbl_brand_benchmark_session_temporary
    (
			benchmark_id, 
            benchmark_key, 
            session_id,
            session_key,
            new_benchmark_id,
            new_benchmark_key, 
            new_session_id,
            new_session_key,
            config_json,
			score_json,
			status_id,
			create_date,
			modified_date,
			is_active  
    )
    SELECT  a.benchmark_id,
			a.benchmark_key,
            b.id as benchmark_session_id,
            b.benchmark_session_key,
			a.new_benchmark_id,
            a.new_benchmark_key,
            -1 as new_session_id,
			uuid() as new_session_key,
            b.config_json,
            b.score_json,
            b.status_id,
            b.create_date,
            b.modified_date,
            b.is_active
    FROM tbl_brand_benchmark_temporary a
    JOIN BenchmarkSession b
		ON a.benchmark_id = b.benchmark_id;
        
        
    INSERT INTO BenchmarkSession
    (
	   benchmark_id,
	   benchmark_session_key,
	   config_json,
	   score_json,
	   status_id,
	   create_date,
	   modified_date,
	   is_active   
    )
    SELECT new_benchmark_id,
			new_session_key,
			config_json,
		   score_json,
		   status_id,
		   create_date,
		   modified_date,
		   is_active  
    FROM tbl_brand_benchmark_session_temporary;
    
    
    UPDATE tbl_brand_benchmark_session_temporary a
	JOIN BenchmarkSession b
		ON  a.new_benchmark_id = b.benchmark_id and a.new_session_key = b.benchmark_session_key
	SET a.new_session_id = b.id
    WHERE a.new_session_id < 0;	    
    
    
        
	-- next, copy to BenchmarkSessionResult
    INSERT INTO BenchmarkSessionResult
    (
		benchmark_id,
        benchmark_session_id,
        result_json,
        result_type_id,
        create_date,
        modified_date
    )
    SELECT  
			d.new_benchmark_id,
            d.new_session_id,
            c.result_json,
            c.result_type_id,
            c.create_date,
            c.modified_date
    FROM tbl_brand_benchmark_temporary a
    JOIN BenchmarkSession b
		ON a.benchmark_id = b.benchmark_id
	JOIN BenchmarkSessionResult c
		ON b.id = c.benchmark_session_id and b.benchmark_id = c.benchmark_id
	JOIN tbl_brand_benchmark_session_temporary d
		ON b.id = d.session_id;

    
    -- next, copy the BenchmarkScore
    INSERT INTO BenchmarkScore
    (
		benchmark_id,
        score_json,
        score_type_id,
        create_date,
        modified_date
    ) 
    SELECT  a.new_benchmark_id,
			b.score_json,
			b.score_type_id,
			b.create_date,
			b.modified_date			
	FROM tbl_brand_benchmark_temporary a
    JOIN BenchmarkScore b
		ON a.benchmark_id = b.benchmark_id;
        
        
	-- next, copy to BenchmarkCompetitorBrands
    INSERT INTO BenchmarkCompetitorBrands
    (
		benchmark_id,
        benchmark_session_id,
        brand_id,
		is_active,
        create_date,
        modified_date
    ) 
	SELECT d.new_benchmark_id as new_benchmark_id,
		   d.new_session_id as new_benchmark_session_id,
		   c.brand_id,
		   c.is_active,
		   c.create_date,
		   c.modified_date
	FROM tbl_brand_benchmark_temporary a
	JOIN BenchmarkSession b
		ON a.benchmark_id = b.benchmark_id 
	JOIN BenchmarkCompetitorBrands c 
		ON a.benchmark_id = c.benchmark_id AND b.id = c.benchmark_session_id AND c.is_active = 1
	JOIN tbl_brand_benchmark_session_temporary d
		ON b.id = d.session_id;
    
    -- next, copy to BrandBenchmark
    INSERT INTO BrandBenchmark
    (
		brand_id,
		benchmark_id
    )
    SELECT 	new_brand_owner_id,
			new_benchmark_id
    FROM tbl_brand_benchmark_temporary;
    
    INSERT INTO UserBrand
    (
		user_id, brand_id
    )
    VALUES ( @user_id, @new_id);
    
    
    -- now, cleaning the data
    -- DELETE FROM tbl_brand_session_temporary WHERE new_session_id >= 0;
	-- DELETE FROM tbl_brand_benchmark_temporary WHERE new_brand_owner_id >= 0;
    -- DELETE FROM tbl_brand_benchmark_session_temporary WHERE new_session_id >= 0;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `CopyBrand_2`(IN pUser_key NVARCHAR(128), IN pBrand_key NVARCHAR(64))
cpBlock: BEGIN

	SET @user_id = (SELECT id FROM User WHERE auth0UserId = pUser_key); 
        
    IF @user_id IS NULL THEN
		SIGNAL SQLSTATE '42927' SET MESSAGE_TEXT = 'User not found';
    END IF;
    
    SET @brandCount =  ( SELECT count(*)
						FROM UserBrand a
						JOIN Brand b
							on a.brand_id = b.id AND a.user_id = @user_id
						WHERE b.brand_key = pBrand_key) ;
	IF @brandCount > 0 THEN
		LEAVE cpBlock;
    END IF;
    
	-- first create a copy of target brand
	SET @new_key = (SELECT UUID());
    
	INSERT INTO Brand
	(	brand_name, 
		brand_key, 
        frequency_id, 
        config_json, 
        origin_id, 
        last_refresh_date, 
        create_date, 
        modified_date,
        is_active, 
        description)
	
	SELECT 	a.brand_name, 
			@new_key, 
            a.frequency_id, 
            a.config_json, 
            a.origin_id, 
            a.last_refresh_date, 
            a.create_date, 
            a.modified_date, 
            1, 
            a.description
	FROM Brand a
	WHERE a.brand_key = pBrand_key;
    
    SET @new_id = ( SELECT LAST_INSERT_ID());
    
    -- now copy brandsession from target brand
    -- first create a temp table
    CREATE TEMPORARY TABLE IF NOT EXISTS tbl_brand_session_temporary
    (
			brand_id int, 
            brand_key varchar(64), 
            new_brand_id int,
            new_brand_key  varchar(64), 
            brand_logo_url varchar(1024),
            session_id int, 
            session_key varchar(64), 
            new_session_id int null,
            new_session_key varchar(64) null, 
            run_status_id int,
            session_create_date datetime, 
            session_modified_date datetime null,
            session_config_json json,
            result_type_id smallint,
            result_json json, 
            result_create_date datetime, 
            result_modified_date datetime null
    );

   -- insert data into temp table for all sessions for that target brand
	INSERT INTO tbl_brand_session_temporary
    (
			brand_id, 
            brand_key, 
            new_brand_id,
            new_brand_key,
            brand_logo_url,
            session_id, 
            session_key, 
            new_session_id,
            new_session_key, 
            run_status_id,
            session_create_date, 
            session_modified_date,
            session_config_json,
            result_type_id,
            result_json, 
            result_create_date, 
            result_modified_date   
    )
    
	SELECT a.id as brand_id, 
            a.brand_key, 
            @new_id,
            @new_key,
            l.brand_logo_url,
            b.id as session_id, 
            b.session_key, 
            -1 as new_session_id,
            UUID() as new_session_key,
            b.run_status_id,
            b.create_date as session_create_date, 
            b.modified_date as session_modified_date,
            b.config_json,
            c.result_type_id,
            c.result_json, 
            c.create_date as session_create_date, 
            c.modified_date as session_modified_date
	FROM ( SELECT id, brand_key
		   FROM Brand 
           WHERE brand_key = pBrand_key) a
	JOIN BrandSession b
		ON a.id = b.brand_id
	JOIN BrandSessionResult c
		ON b.id = c.brand_session_id
	JOIN ResultType d
		ON c.result_type_id = d.id
	LEFT JOIN BrandLogo l
		ON a.id = l.brand_id
	WHERE b.run_status_id IN (3,4, 10);
    
 
	-- create copy of the sessions for target brand from temp table
    
	INSERT INTO BrandSession
	(
		session_key, 
        brand_id, 
        run_status_id, 
        config_json, 
        create_date, 
        modified_date
	)
    SELECT new_session_key,
			new_brand_id,
            run_status_id,
            session_config_json,
			session_create_date, 
            session_modified_date
    FROM tbl_brand_session_temporary;
    
    -- now get the id of the new session records and update the temp table
    UPDATE tbl_brand_session_temporary a
	JOIN BrandSession b
		ON  a.new_session_key = b.session_key
	SET a.new_session_id = b.id
    WHERE a.new_session_id < 0;
            
    -- now copy new records to session results using new ids
	INSERT INTO BrandSessionResult
	(
		brand_session_id, 
        result_type_id, 
        result_json, 
        create_date, 
        modified_date,
        is_active
	)	
    SELECT new_session_id,
            result_type_id,
            result_json, 
            result_create_date, 
            result_modified_date,
            1
    FROM tbl_brand_session_temporary;    
    
    -- now copy the session task
 	INSERT INTO BrandSessionTask
	(
		brand_session_id, 
        content_source_id, 
        content_blob_id, 
        status_id, 
        start_date,
        end_date
	)  
    SELECT a.new_session_id,
			b.content_source_id,
			b.content_blob_id, 
			b.status_id, 
			b.start_date,
			b.end_date
    FROM tbl_brand_session_temporary a
    JOIN BrandSessionTask b
		ON a.session_id = b.brand_session_id;
        
        
    -- copy brand logo    
  	INSERT INTO BrandLogo
	(
		brand_id, 
        brand_logo_url
	) 
    SELECT DISTINCT new_brand_id, 
					brand_logo_url
    FROM tbl_brand_session_temporary LIMIT 1;
    
    -- now Brand Archetype Goal
    INSERT INTO BrandArchetypeGoal
	(
		brand_id,
		archetype_target,
		score_json,
		create_date,
		modified_date
	)

	SELECT @new_id,
			archetype_target,
			score_json,
			create_date,
			modified_date
	FROM ( SELECT id 
			FROM Brand WHERE brand_key = pBrand_key ) a
	JOIN BrandArchetypeGoal b
		ON a.id = b.brand_id;
    
 
 
	-- now copy benchmark
    -- first create a temp table for holding benchmark associated with the owner brand
    CREATE TEMPORARY TABLE IF NOT EXISTS tbl_brand_benchmark_temporary
    (
			brand_owner_id int, 
            brand_owner_key varchar(64), 
            new_brand_owner_id int,
            new_brand_owner_key  varchar(64), 
            benchmark_id int, 
            benchmark_key varchar(64), 
            new_benchmark_id int null,
            new_benchmark_key varchar(64) null, 
            benchmark_name varchar(128) null,
            benchmark_config json,
            benchmark_frequency_id int, 
            benchmark_create_date datetime null,
            benchmark_modified_date datetime null,
            benchmark_is_active bit,
            benchmark_status_id tinyint
    );
    
	CREATE TEMPORARY TABLE IF NOT EXISTS tbl_brand_benchmark_session_temporary
    (
            benchmark_id int, 
            benchmark_key varchar(64), 
            session_id int,
            session_key varchar(64),
            new_benchmark_id int null,
            new_benchmark_key varchar(64) null, 
            new_session_id int,
            new_session_key varchar(64),
            config_json json,
			score_json json null,
			status_id tinyint null,
			create_date datetime ,
			modified_date datetime,
			is_active bit 
    );
    
    
    INSERT INTO tbl_brand_benchmark_temporary
    (
 			brand_owner_id, 
            brand_owner_key, 
            new_brand_owner_id,
            new_brand_owner_key, 
            benchmark_id, 
            benchmark_key, 
            new_benchmark_id,
            new_benchmark_key, 
            benchmark_name,
            benchmark_config,
            benchmark_frequency_id, 
            benchmark_create_date,
            benchmark_modified_date,
            benchmark_is_active,
            benchmark_status_id   
    )
	SELECT a.id as brand_owner_id,
			a.brand_key as brand_owner_key,
			@new_id as new_brand_owner_id,
			@new_key as new_brand_owner_key,
			c.id as benchmark_id,
			c.benchmark_key as benchmark_key,
			-1 as new_benchmark_id,
			uuid() as new_benchmark_key,
			c.name as benchmark_name,
            c.config_json as benchmark_config,
			c.frequency_id as benchmark_frequency_id,
			c.create_date as benchmark_create_date,
			c.modified_date as benchmark_modified_date,
			1 as benchmark_is_active,
			c.status_id as benchmark_status_id
			
	FROM (  SELECT id, brand_key 
			FROM Brand 
			WHERE brand_key = pBrand_key ) a
	JOIN BrandBenchmark b
		ON a.id = b.brand_id
	JOIN Benchmark c
		ON c.id = b.benchmark_id;
        
	
    -- now create new benchmark records
    INSERT INTO Benchmark(
		benchmark_key,
        name,
		config_json,
		frequency_id,
		create_date,
		modified_date,
		is_active,
		status_id    
    )
    SELECT  new_benchmark_key, 
            benchmark_name,
            benchmark_config,
            benchmark_frequency_id, 
            benchmark_create_date,
            benchmark_modified_date,
            benchmark_is_active,
            benchmark_status_id  			
    FROM tbl_brand_benchmark_temporary;
        

    -- now get the id of the new benchmark records and update the temp table
    UPDATE tbl_brand_benchmark_temporary a
	JOIN Benchmark b
		ON  a.new_benchmark_key = b.benchmark_key
	SET a.new_benchmark_id = b.id
    WHERE a.new_benchmark_id < 0;	
    
    -- next, copy the BenchmarkSession
	INSERT INTO tbl_brand_benchmark_session_temporary
    (
			benchmark_id, 
            benchmark_key, 
            session_id,
            session_key,
            new_benchmark_id,
            new_benchmark_key, 
            new_session_id,
            new_session_key,
            config_json,
			score_json,
			status_id,
			create_date,
			modified_date,
			is_active  
    )
    SELECT  a.benchmark_id,
			a.benchmark_key,
            b.id as benchmark_session_id,
            b.benchmark_session_key,
			a.new_benchmark_id,
            a.new_benchmark_key,
            -1 as new_session_id,
			uuid() as new_session_key,
            b.config_json,
            b.score_json,
            b.status_id,
            b.create_date,
            b.modified_date,
            b.is_active
    FROM tbl_brand_benchmark_temporary a
    JOIN BenchmarkSession b
		ON a.benchmark_id = b.benchmark_id;
        
        
    INSERT INTO BenchmarkSession
    (
	   benchmark_id,
	   benchmark_session_key,
	   config_json,
	   score_json,
	   status_id,
	   create_date,
	   modified_date,
	   is_active   
    )
    SELECT new_benchmark_id,
			new_session_key,
			config_json,
		   score_json,
		   status_id,
		   create_date,
		   modified_date,
		   is_active  
    FROM tbl_brand_benchmark_session_temporary;
    
    
    UPDATE tbl_brand_benchmark_session_temporary a
	JOIN BenchmarkSession b
		ON  a.new_benchmark_id = b.benchmark_id and a.new_session_key = b.benchmark_session_key
	SET a.new_session_id = b.id
    WHERE a.new_session_id < 0;	    
    
    
        
	-- next, copy to BenchmarkSessionResult
    INSERT INTO BenchmarkSessionResult
    (
		benchmark_id,
        benchmark_session_id,
        result_json,
        result_type_id,
        create_date,
        modified_date
    )
    SELECT  
			d.new_benchmark_id,
            d.new_session_id,
            c.result_json,
            c.result_type_id,
            c.create_date,
            c.modified_date
    FROM tbl_brand_benchmark_temporary a
    JOIN BenchmarkSession b
		ON a.benchmark_id = b.benchmark_id
	JOIN BenchmarkSessionResult c
		ON b.id = c.benchmark_session_id and b.benchmark_id = c.benchmark_id
	JOIN tbl_brand_benchmark_session_temporary d
		ON b.id = d.session_id;

    
    -- next, copy the BenchmarkScore
    INSERT INTO BenchmarkScore
    (
		benchmark_id,
        score_json,
        score_type_id,
        create_date,
        modified_date
    ) 
    SELECT  a.new_benchmark_id,
			b.score_json,
			b.score_type_id,
			b.create_date,
			b.modified_date			
	FROM tbl_brand_benchmark_temporary a
    JOIN BenchmarkScore b
		ON a.benchmark_id = b.benchmark_id;
        
        
	-- next, copy to BenchmarkCompetitorBrands
    INSERT INTO BenchmarkCompetitorBrands
    (
		benchmark_id,
        benchmark_session_id,
        brand_id,
		is_active,
        create_date,
        modified_date
    ) 
	SELECT d.new_benchmark_id as new_benchmark_id,
		   d.new_session_id as new_benchmark_session_id,
		   c.brand_id,
		   c.is_active,
		   c.create_date,
		   c.modified_date
	FROM tbl_brand_benchmark_temporary a
	JOIN BenchmarkSession b
		ON a.benchmark_id = b.benchmark_id 
	JOIN BenchmarkCompetitorBrands c 
		ON a.benchmark_id = c.benchmark_id AND b.id = c.benchmark_session_id AND c.is_active = 1
	JOIN tbl_brand_benchmark_session_temporary d
		ON b.id = d.session_id;
    
    -- next, copy to BrandBenchmark
    INSERT INTO BrandBenchmark
    (
		brand_id,
		benchmark_id
    )
    SELECT 	new_brand_owner_id,
			new_benchmark_id
    FROM tbl_brand_benchmark_temporary;
    
    INSERT INTO UserBrand
    (
		user_id, brand_id
    )
    VALUES ( @user_id, @new_id);
    
    
    -- now, cleaning the data
    DELETE FROM tbl_brand_session_temporary WHERE new_session_id >= 0;
	DELETE FROM tbl_brand_benchmark_temporary WHERE new_brand_owner_id >= 0;
    DELETE FROM tbl_brand_benchmark_session_temporary WHERE new_session_id >= 0;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `DeleteBenchmarkFromBrand`(IN pBrandKey VARCHAR(64), 
															 IN pBenchmarkKey VARCHAR(64))
BEGIN
	
	UPDATE BrandBenchmark a
    JOIN Brand b 
		on a.brand_id = b.id
	JOIN Benchmark c 
        on a.benchmark_id = c.id
	SET a.is_active = 0,
        c.is_active = 0,
		a.modified_date = now(),
        c.modified_date = now()
	WHERE b.brand_key = pBrandKey and c.benchmark_key = pBenchmarkKey;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `DeleteBrandFromUser`(IN pUserId VARCHAR(64), 
															 IN pBrandKey VARCHAR(64))
BEGIN
	
	UPDATE UserBrand a
    JOIN Brand b 
		on a.brand_id = b.id
	JOIN User c 
        on a.user_id = c.id
	SET a.is_active = 0,
		a.modified_date = now()
	WHERE b.brand_key = pBrandKey and c.auth0UserId = pUserId;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `DeleteUserMessage`( IN pMessageId INT(11))
BEGIN
	UPDATE Message
    SET
		deleted = 1,
        modified_date = now()
    WHERE
		id = pMessageId;
	
    COMMIT;
	SELECT * FROM Message WHERE id = pMessageId;
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetAllBrandBenchmarkScoresByKey`(IN pBrandKey VARCHAR(64), IN pScoreType VARCHAR(32))
BEGIN
	


	SELECT br.id as brand_id,
			br.brand_name,
			pBrandKey as brand_key, 
            a.benchmark_key, 
            a.name as benchmark_name, 
            b.score_json, 
            c.name as score_type
    
    FROM ( SELECT id, brand_name 
		   FROM Brand
           WHERE brand_key = pBrandKey ) br
    JOIN BrandBenchmark y
		on br.id = y.brand_id and y.is_active = 1
    JOIN Benchmark a
		on a.id = y.benchmark_id and a.is_active = 1
    JOIN BenchmarkScore b
		ON a.id = b.benchmark_id 
    JOIN ScoreType c 
		on b.score_type_id = c.id
    WHERE  c.name = pScoreType;
    
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBenchmarkCompetitorBrandsStatus`(IN pBenchmarkId INT, IN pBenchmarkSessionId INT)
BEGIN

	select x.benchmark_id, 
			x.brand_id, 
            x.session_id, 
            e.run_status_id,
		    CASE WHEN r.id IS NOT NULL 
				THEN 1
				ELSE 0
		   END AS output_exist
	from
	(
		select a.id as benchmark_id, c.id as brand_id, max(d.id) as session_id
		from Benchmark a
		join BenchmarkCompetitorBrands b
			on a.id = b.benchmark_id and a.is_active = 1 and b.is_active = 1 and a.id = pBenchmarkId and b.benchmark_session_id = pBenchmarkSessionId
		join Brand c
				on b.brand_id = c.id
		join BrandSession d
				on c.id = d.brand_id
		group by a.id, c.id 
	) x
	join BrandSession e
	  on x.session_id = e.id
	left join BrandSessionResult r
      on e.id = r.brand_session_id;
	
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBenchmarkConfiguration`( pBrandId INT, pBenchmarkId INT)
BEGIN
	
	SELECT a.id as benchmark_id, a.name as benchmark_name, b.brand_id, a.config_json
	FROM Benchmark  a
	JOIN BrandBenchmark b
		ON a.id = b.benchmark_id
	WHERE b.brand_id = pBrandId and b.benchmark_id = pBenchmarkId;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBenchmarkConfiguration2`( pBrandKey VARCHAR(64), pBenchmarkKey VARCHAR(64))
BEGIN
	
	SELECT a.id as benchmark_id, a.name as benchmark_name, b.brand_id, a.config_json
	FROM Benchmark  a
	JOIN BrandBenchmark b
		ON a.id = b.benchmark_id
	JOIN Brand c
		ON b.brand_id = c.id
	WHERE a.benchmark_key = pBenchmarkKey and c.brand_key = pBrandKey;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBenchmarkConfigurationByKey`(IN pBrandKey VARCHAR(64), IN pBenchmarkKey varchar(64))
BEGIN
	
    SELECT a.brand_name, 
			a.brand_key, 
			a.description as brand_description,
			a.create_date, 
            a.modified_date, c.name as benchmark_name, c.benchmark_key, c.status_id, c.config_json, c.create_date as benchmark_create_date, c.modified_date as benchmark_modified_date
    FROM Brand a
    JOIN BrandBenchmark b 
		on a.id = b.brand_id and a.brand_key = pBrandKey
	JOIN Benchmark c
		on b.benchmark_id = c.id and c.benchmark_key = pBenchmarkKey
    ORDER BY c.create_date DESC;
    
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBenchmarkScore`(IN pBenchmarkId INT, IN pScoreType VARCHAR(32))
BEGIN
	SELECT a.id as benchmark_id, a.benchmark_key,  a.name as benchmark_name, b.score_json, a.status_id
    FROM Benchmark a
    JOIN BenchmarkScore b
		ON a.id = b.benchmark_id 
    JOIN ScoreType c 
		on b.score_type_id = c.id
    WHERE a.id = pBenchmarkId and c.name = pScoreType;
    
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBenchmarkScoreByKey`(IN pBenchmarkKey VARCHAR(64), IN pScoreType VARCHAR(32))
BEGIN
	SELECT a.benchmark_key, a.name as benchmark_name, b.score_json, c.name as score_type
    FROM Benchmark a
    JOIN BenchmarkScore b
		ON a.id = b.benchmark_id and a.benchmark_key = pBenchmarkKey
    JOIN ScoreType c 
		on b.score_type_id = c.id
    WHERE  c.name = pScoreType;
    
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBenchmarkSessionConfiguration`( pBenchmarkId INT, pBenchmarkSessionId INT)
BEGIN
	
	SELECT b.id as benchmark_id, 
			b.benchmark_key,
			b.name as benchmark_name, 
            a.id as benchmark_session_id,
            a.benchmark_session_key,
            a.config_json, 
            a.create_date as benchmark_session_date
	FROM  BenchmarkSession a
    JOIN Benchmark b
		on a.benchmark_id = b.id and b.id = pBenchmarkId and a.id = pBenchmarkSessionId;
	-- WHERE id = pBenchmarkSessionId and  benchmark_id = pBenchmarkId;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBenchmarkSessionResult`(IN pBenchmarkId INT, IN pScoreType VARCHAR(32))
BEGIN
	
    SET @pResultTypeId = ( SELECT Id FROM ScoreType WHERE name = pScoreType LIMIT 1);

   IF @pResultTypeId IS NULL THEN
	
	   SELECT a.id, a.benchmark_key, a.name,  b.benchmark_session_id, b.result_json, b.result_type_id, b.create_date 
	   FROM Benchmark a
	   JOIN BenchmarkSessionResult b
			ON a.id = b.benchmark_id  and a.id = pBenchmarkId 
	   ORDER BY b.id DESC; 
       
	ELSE 
	   SELECT a.id, a.benchmark_key, a.name, b.result_json,  b.benchmark_session_id, b.result_type_id, b.create_date 
	   FROM Benchmark a
	   JOIN BenchmarkSessionResult b
			ON a.id = b.benchmark_id  and a.id = pBenchmarkId and b.result_type_id = @pResultTypeId
	   ORDER BY b.id DESC; 
    
    END IF;
  
    
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBenchmarksToSchedule`()
BEGIN

	SELECT  u.auth0UserId as userId, b.id as brand_id, b.brand_key, bm.*
    FROM (
-- 		SELECT a.id as benchmark_id, a.benchmark_key, a.modified_date, a.status_id
-- 		FROM Benchmark a    
-- 		WHERE is_active = 1 and status_id IN (3,4,5) 
-- 		
-- 		union 
		
		SELECT a.id as benchmark_id, a.benchmark_key, a.modified_date, a.status_id
		FROM Benchmark a
		WHERE is_active = 1 and ( status_id IN (3,4,5) and datediff(now(),a.modified_date) >= 30)
	) bm
    JOIN BrandBenchmark bb
		ON bm.benchmark_id = bb.benchmark_id and bb.status_id = 1 and bb.is_active = 1
	JOIN Brand b
		ON b.id = bb.brand_id
	JOIN UserBrand ub
		ON b.id = ub.brand_id
	JOIN User u
		ON u.id = ub.user_id;
	
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBenchmarksToScore`()
BEGIN

	SELECT n.id as benchmark_id, n.benchmark_key, n.name as benchmark_name, 
		   m.id as benchmark_session_id, m.benchmark_session_key
	FROM
	(
		SELECT c.benchmark_id, max(c.id) as max_session_id
		FROM
		(
			SELECT a.id as benchmark_id
			FROM Benchmark a
			WHERE a.is_active = 1 and a.status_id = 2 --  will be chnaged to 2

		) b
		JOIN BenchmarkSession c 
			on b.benchmark_id = c.benchmark_id and c.status_id = 1
		group by c.benchmark_id, c.id
    ) l    
	JOIN BenchmarkSession m
		ON l.benchmark_id = m.benchmark_id and l.max_session_id = m.id
	JOIN Benchmark n
		ON n.id = m.benchmark_id;

	
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBenchmarkSummary`(IN pBenchmarkKey varchar(64))
BEGIN
	
    SELECT 	c.id as benchmark_id,
			c.benchmark_key,
			c.name as benchmark_name,  
            c.status_id, 
            c.config_json, 
            c.create_date as benchmark_create_date, 
            c.modified_date as benchmark_modified_date
    FROM Benchmark c
	WHERE c.benchmark_key = pBenchmarkKey;
	
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandArchetypeGoal`(IN pBrandKey VARCHAR(64))
BEGIN

		SELECT ba.*, br.brand_name
        FROM BrandArchetypeGoal ba
        INNER JOIN Brand br
        ON br.id = ba.brand_id
        WHERE br.brand_key = pBrandKey;
        
        

	
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandArchetypeGoal2`(IN pBrandId INT)
BEGIN

		SELECT *
        FROM BrandArchetypeGoal
        WHERE brand_id = pBrandId;

	
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandBenchmarkList`(IN pBrandKey VARCHAR(64))
BEGIN
	SELECT a.brand_name, 
			a.brand_key, 
            a.create_date, 
            a.modified_date, 
            c.name as benchmark_name, 
            c.benchmark_key, 
            c.status_id, 
            c.config_json, 
            c.create_date as benchmark_create_date, 
            c.modified_date as benchmark_modified_date
    FROM Brand a
    JOIN BrandBenchmark b 
		on a.id = b.brand_id  and a.brand_key = pBrandKey and b.is_active = 1
	JOIN Benchmark c
		on b.benchmark_id = c.id and b.is_active = 1
    ORDER BY c.create_date DESC;
    
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandBenchmarkResult`(IN pBrandKey VARCHAR(64), IN pBenchmarkKey VARCHAR(64))
BEGIN
	set @brand_id = (SELECT id 
					 FROM Brand
					 WHERE brand_key = pBrandKey ); 

	set @benchmark_id = (SELECT id 
					 FROM Benchmark
					 WHERE benchmark_key = pBenchmarkKey ); 
                     
	SELECT n.benchmark_key, n.name as benchmark_name, m.score_json
	FROM
	(
		SELECT c.benchmark_id, max(c.id) as max_session_id
		FROM
		(
			SELECT b.benchmark_id
			FROM Benchmark a
			JOIN BrandBenchmark b
				ON a.id = b.benchmark_id and b.brand_id = @brand_id and b.benchmark_id = @benchmark_id

		) f
		JOIN BenchmarkSession c 
			on f.benchmark_id = c.benchmark_id
		group by c.benchmark_id, c.id
		
	) l
	JOIN BenchmarkSession m
		ON l.benchmark_id = m.benchmark_id and l.max_session_id = m.id
	JOIN Benchmark n
		ON n.id = m.benchmark_id
	WHERE m.status_id = 3;  
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandBenchmarkSummary`(IN pBrandKey VARCHAR(64))
BEGIN
	set @brand_id = (SELECT id 
					 FROM Brand
					 WHERE brand_key = pBrandKey ); 


	SELECT n.benchmark_key, n.name as benchmark_name, m.status_id
	FROM
	(
		SELECT c.benchmark_id, max(c.id) as max_session_id
		FROM
		(
			SELECT b.benchmark_id
			FROM Benchmark a
			JOIN BrandBenchmark b
				ON a.id = b.benchmark_id and b.brand_id = @brand_id

		) f
		JOIN BenchmarkSession c 
			on f.benchmark_id = c.benchmark_id
		group by c.benchmark_id, c.id
		
	) l
	JOIN BenchmarkSession m
		ON l.benchmark_id = m.benchmark_id and l.max_session_id = m.id
	JOIN Benchmark n
		ON n.id = m.benchmark_id;
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandInfoByKey`(IN pBrandKey VARCHAR(64))
BEGIN


	SELECT a.id as brand_id, 
			a.brand_key, 
            a.brand_name, 
            a.description,
            a.create_date,
            a.modified_date,
            d.brand_logo_url,
            b.name as origin, 
            a.config_json, 
            c.name as frequency
	FROM Brand a
	JOIN OriginType b
		ON a.origin_id = b.id
	JOIN ScheduleFrequency c
		ON a.frequency_id = c.id
	LEFT JOIN BrandLogo d
		ON a.id = d.brand_id
	WHERE a.brand_key = pBrandKey;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandInfoConfig`(IN pBrandId INT)
BEGIN


	SELECT a.id as brand_id, a.brand_key, a.brand_name, b.name as origin, a.config_json, c.name as frequency
	FROM Brand a
	JOIN OriginType b
		ON a.origin_id = b.id
	JOIN ScheduleFrequency c
		ON a.frequency_id = c.id
	WHERE a.id = pBrandId;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandInfoConfigByKey`(IN pBrandKey VARCHAR(64))
BEGIN


	SELECT a.id as brand_id, 
			a.brand_key, 
            a.brand_name, 
            a.description,
            a.create_date,
            a.modified_date,
            d.brand_logo_url,
            b.name as origin, 
            a.config_json, 
            c.name as frequency
	FROM Brand a
	JOIN OriginType b
		ON a.origin_id = b.id
	JOIN ScheduleFrequency c
		ON a.frequency_id = c.id
	LEFT JOIN BrandLogo d
		ON a.id = d.brand_id
	WHERE a.brand_key = pBrandKey;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandList`(IN pUserId VARCHAR(64))
BEGIN
	
    select d.brand_id, 
			c.brand_key, 
            c.brand_name, 
            c.description as brand_description,
            c.create_date as brand_create_date, 
            c.last_refresh_date as brand_refresh_date, 
            d.config_json as brand_config,  
            d.create_date as session_create_date, 
            d.create_date as session_date, 
            d.modified_date as session_refresh_date,
            d.session_key,
			d.run_status_id as brand_status_id,
            l.brand_logo_url,
            z.is_active
    from 
    (
		select c.id as brand_id, max(d.id) as session_id, a.is_active
		from UserBrand a
		join User b
			on a.user_id = b.id
		join Brand c
			on a.brand_id = c.id
		join BrandSession d
			on c.id = d.brand_id
		where auth0UserId = pUserId  and ( c.origin_id = 1 or c.origin_id = 2 )   -- and is_active = 1 and c.origin_id = 2
		group by c.id , a.is_active
    ) z
    JOIN BrandSession d
		on z.brand_id = d.brand_id and z.session_id = d.id
	JOIN Brand c
		on d.brand_id = c.id
	LEFT JOIN BrandLogo l
		on c.id = l.brand_id
	order by d.create_date desc;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandMetaConfig`(brand VARCHAR(64))
BEGIN
	select *
	from Brand
	where brand_name like CONCAT(brand, '%' )    and origin_id = 1 and is_active = 1;
    
    
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandScoreResults`( pBrandId INT, pResultType VARCHAR(32))
BEGIN
	
    set @resultType = pResultType;
    
    if @resultType is null then
		set @resultType = 'All Scores';
    end if;
    
	SELECT a.id as brand_id,  b.id as session_id, b.create_date as session_date, result_json
	FROM Brand a
	JOIN BrandSession b
		ON a.id = b.brand_id
	JOIN BrandSessionResult c
		ON b.id = c.brand_session_id
	JOIN ResultType d
		ON c.result_type_id = d.id
	WHERE a.id = pBrandId and d.name = @resultType;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandScoreResultsByKey`( IN pBrandKey VARCHAR(64), IN pResultType VARCHAR(32))
BEGIN
	
    set @resultType = pResultType;
    
    if @resultType is null then
		set @resultType = 'All Scores';
    end if;
    
	SELECT a.id as brand_id, a.brand_key, a.brand_name, b.id as session_id, b.session_key, b.create_date as session_date, result_json, d.name as result_type
	FROM Brand a
	JOIN BrandSession b
		ON a.id = b.brand_id
	JOIN BrandSessionResult c
		ON b.id = c.brand_session_id
	JOIN ResultType d
		ON c.result_type_id = d.id
	WHERE a.brand_key = pBrandKey and d.name = @resultType;
    


END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandSessionArchetypeGoal`(IN pBrandId INT)
BEGIN

		SELECT id as arche_goal_id, brand_id
        FROM BrandArchetypeGoal
        WHERE brand_id = pBrandId;

	
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandSessionArchetypeScore`(IN pSessionKey VARCHAR(128), IN pScoreType VARCHAR(32))
BEGIN

		SELECT session_key, score_type, score_json, modified_date
        FROM BrandSessionArchetypeScore
        WHERE session_key =  pSessionKey and score_type = pScoreType;

	
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandSessionBlobInfo`(IN pBrandKey VARCHAR(64), IN pSessionKey VARCHAR(64), IN pSourceId INT, IN pBlobId INT )
BEGIN

		set @brand_session_id = ( SELECT id FROM BrandSession WHERE session_key = pSessionKey );

		SELECT  c.blob_uri, c.blob_size, c.max_blob_timestamp as blob_timestamp, c.create_date as blob_date
		from  BrandSessionTask a
		JOIN ContentBlobMetaInfo c 
			on a.content_blob_id = c.id
		WHERE a.brand_session_id = @brand_session_id and a.content_source_id = pSourceId and a.content_blob_id = pBlobId;
                
	
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandSessionBlobInfoBySource`(IN pBrandKey VARCHAR(64), IN pSessionKey VARCHAR(64), IN pSourceType VARCHAR(128), IN pSourceHandle VARCHAR(128) )
BEGIN

		set @brand_session_id = ( SELECT id FROM BrandSession WHERE session_key = pSessionKey );
		set @src_id = ( select a.id		
					 from ContentSource a
					 JOIN ChannelType b
						on a.channel_type_id = b.id
					  WHERE handle_id = pSourceHandle and  b.name = pSourceType);
                      
		SELECT  c.blob_uri, c.blob_size, c.max_blob_timestamp as blob_timestamp, c.create_date as blob_date
		from  BrandSessionTask a
		JOIN ContentBlobMetaInfo c 
			on a.content_blob_id = c.id
		WHERE a.brand_session_id = @brand_session_id and a.content_source_id = @src_id;
                
	
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandSessionBlobQuery`()
BEGIN
	set @dt = now();
	SELECT a.id as brand_id,  a.brand_key, b.id as session_id, b.session_key, a.frequency_id
    FROM Brand a
    JOIN BrandSession b 
		on a.id = b.brand_id
	-- JOIN UserBrand ub
	--	on a.id = ub.brand_id
    WHERE b.run_status_id = 1 and a.is_active = 1
		  and datediff(@dt, b.create_date) < 3 -- last 3 days
    ORDER BY b.create_date ASC
    LIMIT 100;
    
    
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandSessionBlobQueryToProcess`()
BEGIN
	set @dt = now();
	SELECT a.id as brand_id,  a.brand_key, b.id as session_id, b.session_key, a.frequency_id
    FROM Brand a
    JOIN BrandSession b 
		on a.id = b.brand_id
	-- JOIN UserBrand ub
	--	on a.id = ub.brand_id
    WHERE ( b.run_status_id = 1 or b.run_status_id = 10 )  and a.is_active = 1
		  and datediff(@dt, b.create_date) < 3 -- last 3 days
    ORDER BY b.create_date ASC
    LIMIT 16;
    
    
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandSessionConfig`(IN pSessionKey VARCHAR(64))
BEGIN
	SELECT id as session_id, session_key, config_json
    FROM BrandSession
    WHERE session_key = pSessionKey and run_status_id >= 1;
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandSessionDetail`(IN pUserId VARCHAR(64), pBrandKey VARCHAR(64), pSessionKey VARCHAR(64))
BEGIN
	
	SELECT a.id as brand_id, 
			brand_name, 
            brand_key, 
            a.description as brand_description,
            a.create_date as brand_create_date,
            a.modified_date as brand_refresh_date,
            l.brand_logo_url,
            b.id as session_id, 
            b.session_key, 
            b.run_status_id,
            b.create_date as session_date,
            b.create_date as session_create_date, 
            b.modified_date as session_modified_date,
            b.config_json,
            result_json, 
            name as result_type
	FROM Brand a
	JOIN BrandSession b
		ON a.id = b.brand_id and b.session_key = pSessionKey
	JOIN BrandSessionResult c
		ON b.id = c.brand_session_id
	JOIN ResultType d
		ON c.result_type_id = d.id
	LEFT JOIN BrandLogo l
		on a.id = l.brand_id
	WHERE a.brand_key = pBrandKey and  b.run_status_id >= 3;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandSessionInfoConfig`(IN pBrandId INT, IN pSessionKey VARCHAR(64))
BEGIN
	-- SET @brand_name = ( SELECT brand_name FROM Brand WHERE id = pBrandId );
    
	SELECT br.brand_id, 
			br.brand_key, 
            br.brand_name, 
            bs.id as session_id, 
            bs.session_key, 
            bs.config_json, 
            br.origin, 
            br.frequency,
            bs.create_date as session_date
    FROM (
		SELECT a.id as brand_id, a.brand_key, a.brand_name, b.name as origin, c.name as frequency
        FROM Brand a
        JOIN OriginType b
			ON a.origin_id = b.id
		JOIN ScheduleFrequency c
			ON a.frequency_id = c.id
        WHERE a.id = pBrandId
    ) br
    join BrandSession bs
		ON br.brand_id = bs.brand_id
    WHERE bs.brand_id = pBrandId and session_key = pSessionKey and run_status_id >= 1;
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandSessionInfoConfigByKey`(IN pBrandId INT, IN pSessionId INT)
BEGIN

    
	SELECT br.brand_id, br.brand_key, br.brand_name, bs.id as session_id, bs.session_key, bs.config_json, br.origin, br.frequency
    FROM (
		SELECT a.id as brand_id, a.brand_key, a.brand_name, b.name as origin, c.name as frequency
        FROM Brand a
        JOIN OriginType b
			ON a.origin_id = b.id
		JOIN ScheduleFrequency c
			ON a.frequency_id = c.id
        WHERE a.id = pBrandId
    ) br
    join BrandSession bs
		ON br.brand_id = bs.brand_id
    WHERE bs.brand_id = pBrandId and bs.id = pSessionId and run_status_id >= 1;
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandSessionScoreResult`( pSessionKey VARCHAR(64))
BEGIN
	
	SELECT  a.id as brand_id, a.brand_key, a.brand_name, b.id as session_id, b.session_key, c.create_date as result_date, result_json, name as result_type
	FROM Brand a
    JOIN BrandSession b
		on a.id = b.brand_id and b.session_key = pSessionKey
	JOIN BrandSessionResult c
		ON b.id = c.brand_session_id
	JOIN ResultType d
		ON c.result_type_id = d.id
	WHERE d.id = 1;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandSessionStatus`(IN pUserId VARCHAR(64), pBrandKey VARCHAR(64), pSessionKey VARCHAR(64))
BEGIN
	
	SELECT a.id as brand_id, brand_name, brand_key, b.id as session_id, b.session_key, b.run_status_id, 
			b.create_date as session_create_date, 
			b.modified_date as session_modified_date
	FROM Brand a
	JOIN BrandSession b
		ON a.id = b.brand_id and a.brand_key = pBrandKey
	WHERE b.session_key = pSessionKey;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandSetupRequestsToProcess`()
BEGIN
	SELECT b.id as request_id, b.brand_id, priority, create_date
    FROM
    (
		SELECT brand_id, MIN(id) as min_req_id
		FROM BrandSetupRequest
		WHERE status_id = 1
		GROUP BY brand_id
	) a
    JOIN BrandSetupRequest b
		ON a.min_req_id = b.id
    ORDER BY priority DESC, create_date ASC
    LIMIT 20;
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandsToSchedule`()
BEGIN
	set @dt = now();
	SELECT  a.id AS brand_id, a.brand_key, a.brand_name, datediff(@dt,a.last_refresh_date ) as diffInDays , last_refresh_date
    FROM Brand a
    JOIN ScheduleFrequency b
		ON a.frequency_id = b.id
	JOIN UserBrand c
		ON a.id = c.brand_id and c.is_active = 1
	-- WHERE datediff(@dt,a.last_refresh_date ) >=  b.day_interval and datediff(@dt, a.last_refresh_date ) <= 60  and a.is_active = 1
    WHERE datediff(@dt,a.last_refresh_date ) >= 30 and datediff(@dt,a.last_refresh_date ) <= 60 and a.is_active = 1
    and a.origin_id in (2)
	and a.id not in (
    
		SELECT brand_id
		FROM BrandSetupRequest
		WHERE status_id = 1
	)
    LIMIT 3;
    
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetBrandsToSchedule_bk`()
BEGIN
	set @dt = now();
	SELECT  a.id AS brand_id, a.brand_key, a.brand_name, datediff(@dt,a.last_refresh_date ) as diffInDays , last_refresh_date
    FROM Brand a
    JOIN ScheduleFrequency b
		ON a.frequency_id = b.id
	WHERE datediff(@dt,a.last_refresh_date ) >=  30  and a.is_active = 1
	-- WHERE datediff(@dt,a.last_refresh_date ) >=  b.day_interval and a.is_active = 1;
	and a.id not in (
    
		SELECT brand_id
		FROM BrandSetupRequest
		WHERE status_id = 1
	)
    LIMIT 20;
    
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetConfiguredSource`(IN pSourceName VARCHAR(128), IN pHandleIds VARCHAR(128) )
BEGIN
	set @ids = JSON_EXTRACT(pHandleIds,'$');
	SELECT a.id, handle_id, channel_type_id
	from ContentSource a
	JOIN ChannelType b
		on a.channel_type_id = b.id
	WHERE JSON_CONTAINS(@ids, JSON_ARRAY(handle_id)) and  b.name = pSourceName;
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetFreeUsers`()
BEGIN
	SELECT a.auth0UserId as id, a.email, b.level_id as level
	FROM User a
	join Account b
		on a.accountId = b.Id
	where b.level_id < 2;
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetLogoLinkToUpdate`()
BEGIN

	select  
			a.id as brand_id,  
            b.id as brand_session_id,
            c.id as logo_id,
            brand_logo_url, 
            a.config_json as br_cfg, 
            b.config_json as session_cfg,
            c.modified_date as logo_updated
	from
	(
		select  b.id as br_id, max(c.id) as max_sid
		from User z
        join UserBrand a 
			on z.id = a.user_id
		join Brand  b
			on a.brand_id = b.id and a.is_active = 1 and a.user_id >= 1 and b.origin_id = 2
		join BrandSession c
			on b.id = c.brand_id
		group by b.id ) brm
	join Brand a
		on a.id = brm.br_id
	join BrandSession b
		on b.id = brm.max_sid and  b.brand_id = brm.br_id
	join BrandLogo c
		on a.id = c.brand_id
	where brand_logo_url like '%cdn%' and datediff(now(), c.modified_date) >= 7
    limit 100;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetModuleConfiguration`( pModuleName VARCHAR(128), pSubModuleName VARCHAR(128))
BEGIN
	
	SELECT module_name, sub_module_name, type_name, config_json
	FROM ModuleConfiguration
	WHERE module_name = pModuleName and sub_module_name = pSubModuleName;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetModuleConfigurationByType`( pModuleName VARCHAR(128), pSubModuleName VARCHAR(128), pTypeName VARCHAR(128))
BEGIN
	
	SELECT module_name, sub_module_name, type_name, config_json
	FROM ModuleConfiguration
	WHERE module_name = pModuleName and sub_module_name = pSubModuleName and type_name = pTypeName;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetPaymentInfo`(IN pUserId VARCHAR(128))
BEGIN
	SELECT paymentMethodId, b.email, customerId
    FROM Payment a
    JOIN User b
		ON a.user_id = b.id
    WHERE b.auth0UserId = pUserId;
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetPaymentList`(IN pUserId VARCHAR(64))
BEGIN
    select 	b.email, 
			paymentMethodId, 
            customerId
    FROM Payment a
    JOIN User b
		ON a.user_id = b.id
    WHERE b.auth0UserId = pUserId;
    
    
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetSourceBlobInfo`(IN pSourceName VARCHAR(128), IN pSourceHandle VARCHAR(128)  )
BEGIN

		set @src_id = ( select a.id		
					 from ContentSource a
					 JOIN ChannelType b
						on a.channel_type_id = b.id
					  WHERE handle_id = pSourceHandle and  b.name = pSourceName);
                      
		set @src_blob_id = ( select  id
							 from ContentBlobMetaInfo
                             WHERE content_source_id = @src_id
                             ORDER BY create_date desc
                             LIMIT 1);

		SELECT a.id as source_id, a.handle_id, c.id as blob_id, c.create_date as blob_date, blob_size
		from ContentSource a
		JOIN ContentBlobMetaInfo c 
			on a.id = c.content_source_id
		WHERE a.id = @src_id and c.id = @src_blob_id;
                
	
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetUserAccountLevel`(IN pUserId VARCHAR(64))
BEGIN
	
	SELECT a.id, b.level_id as level, b.level_id
	FROM User a
	join Account b
		on a.accountId = b.Id
	where auth0UserId = pUserId;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetUserMessages`( IN pUserId VARCHAR(128))
BEGIN
    SELECT a.id, a.msg_id as message_id, b.cat_id, a.user_id as user_id, b.msg_content as message, b.urge_id as urgency, a.is_read, a.create_date
	FROM UserMessage  a
	JOIN Message b
		ON a.msg_id = b.id
	WHERE a.user_id = pUserId and b.deleted <> 1 order by a.id desc;
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `GetUserProfile`(IN pUserId VARCHAR(128))
BEGIN
	DECLARE companyName VARCHAR(128);
	DECLARE roleType VARCHAR(64);
    
    SET companyName = (SELECT name from Company c INNER JOIN User u ON c.id = u.companyId WHERE u.auth0UserId = pUserId);
    SET roleType = (SELECT name from RoleType r INNER JOIN User u ON r.id = u.roleTypeId WHERE u.auth0UserId = pUserId);
    
	SELECT email, 
			auth0UserId, 
            authSource, 
            emailVerified, 
            firstName, 
            lastName, 
            phone,
            lastLogin, 
            loginsCount, 
            picture,
            a.is_active  , 
            companyName, 
            roleType,
            c.id as level,
            interstitialCount
	FROM User a
    join Account b
		on a.accountId = b.id
	join AccountLevel c
		on b.level_id = c.id
    WHERE auth0UserId = pUserId;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `InsertBrandSessionBlob`(IN pBrandKey VARCHAR(64), 
															 IN pBrandSessionKey VARCHAR(64), 
                                                             IN pContentSourceId INT,
                                                             IN pBlobInfo json)
BEGIN
	
    set @dt = now();

	set @blob_uri = JSON_UNQUOTE(JSON_EXTRACT(pBlobInfo,'$.BlobUri'));
	set @blob_size = JSON_EXTRACT(pBlobInfo,'$.BlobSize');
    set @blob_ts = JSON_UNQUOTE(JSON_EXTRACT(pBlobInfo,'$.BlobTimestamp'));
    
	set @session_id = (select * from BrandSession where session_key = pBrandSessionKey );
    
	INSERT INTO ContentBlobMetaInfo
		(content_source_id, blob_uri, blob_size, max_blob_timestamp,  create_date)
	VALUES
		(@pContentSourceId, @blob_uri, @blob_size, @blob_ts, @dt);
        
    set @content_blob_id = ( SELECT LAST_INSERT_ID());
    
	UPDATE BrandSessionTask
    SET content_blob_id = @content_blob_id,
         end_date = @dt
    WHERE brand_session_id = @session_id AND content_source_id = pContentSourceId;
    

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `InsertBrandSessionBlob2`(IN pBrandKey VARCHAR(64), 
															 IN pBrandSessionKey VARCHAR(64), 
                                                             IN pSourceType VARCHAR(128),
                                                             IN pSourceHandle VARCHAR(128),
                                                             IN pBlobInfo json)
BEGIN
	
    set @dt = now();

	set @blob_uri = JSON_UNQUOTE(JSON_EXTRACT(pBlobInfo,'$.BlobUri'));
	set @blob_size = JSON_EXTRACT(pBlobInfo,'$.BlobSize');
    set @blob_ts = JSON_UNQUOTE(JSON_EXTRACT(pBlobInfo,'$.BlobTimestamp'));
    
	set @session_id = (select id from BrandSession where session_key = pBrandSessionKey );
    
    set @source_id = ( 	SELECT a.id
						from ContentSource a
						JOIN ChannelType b
							on a.channel_type_id = b.id
						WHERE handle_id = pSourceHandle and  b.name = pSourceType); 
    
	INSERT INTO ContentBlobMetaInfo
		(content_source_id, blob_uri, blob_size, max_blob_timestamp,  create_date)
	VALUES
		(@source_id, @blob_uri, @blob_size, @blob_ts, @dt);
        
    set @content_blob_id = ( SELECT LAST_INSERT_ID());
    
	UPDATE BrandSessionTask
    SET content_blob_id = @content_blob_id,
         end_date = @dt
    WHERE brand_session_id = @session_id AND content_source_id = @source_id;
    

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `MarkUserMessage`( IN pUserId VARCHAR(255), IN pMessageId INT(11), IN pIsRead bit(1))
BEGIN
	UPDATE UserMessage
    SET
		is_read = pIsRead
    WHERE
		user_id = pUserId and msg_id = pMessageId;
        
	COMMIT;
    
    SELECT * FROM UserMessage WHERE user_id = pUserId and msg_id = pMessageId;
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `NewBrandSession`(IN pUserId VARCHAR(64), 
															 IN pBrandSessionId VARCHAR(64), 
                                                             IN pBrandSessionConfig json)
BEGIN
	
    set @dt = now();

	set @brand_name = JSON_UNQUOTE(JSON_EXTRACT(pBrandSessionConfig,'$.Brand'));

	set @i_freq = JSON_UNQUOTE(JSON_EXTRACT(pBrandSessionConfig,'$.Frequency'));
	set @freq_id = (select id from ScheduleFrequency where name = @i_freq );
    
    if @freq_id is null then
		set @freq_id = 1;
    end if;
    
	set @i_orig = JSON_UNQUOTE(JSON_EXTRACT(pBrandSessionConfig,'$.Origin'));
	set @orig_id = ( select id from OriginType where name = @i_orig );
    
    set @descr = JSON_UNQUOTE(JSON_EXTRACT(pBrandSessionConfig,'$.Description'));
    
	if @orig_id is null then
		set @orig_id = 1;
    end if;
    

	INSERT INTO Brand
		(brand_name, brand_key, frequency_id, config_json, origin_id, create_date, description)
	VALUES
		(@brand_name, pBrandSessionId, @freq_id, pBrandSessionConfig, @orig_id, @dt, @descr)
	ON DUPLICATE KEY UPDATE
		modified_date  = now();
	
    
    set @brand_id = ( SELECT LAST_INSERT_ID());
    
    INSERT INTO BrandSession
    (
		session_key, brand_id, run_status_id, config_json, create_date
    )
    VALUES
    (
		pBrandSessionId, @brand_id, 1, pBrandSessionConfig, @dt
    );
    
    set @brand_session_id = ( SELECT LAST_INSERT_ID());
    
    IF pUserId is not null and LENGTH(pUserId) > 0 then
    
		set @user_id = (select id from User where auth0UserId = pUserId );
        
        insert into UserBrand
        (
			user_id, brand_id
        )
        VALUES
        (
			@user_id ,  @brand_id
        );
    
    end if;
    
    select @brand_id as brand_id, @brand_session_id as brand_session_id;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `ProvisionNewBrand`(IN pUserId VARCHAR(64), 
                                                               IN pBrandConfig json)
BEGIN
	
    set @dt = now();

	set @bid = JSON_UNQUOTE(JSON_EXTRACT(pBrandConfig,'$.Id'));
	set @brand_name = JSON_UNQUOTE(JSON_EXTRACT(pBrandConfig,'$.Brand'));

	set @i_freq = JSON_UNQUOTE(JSON_EXTRACT(pBrandConfig,'$.Frequency'));
	set @freq_id = (select id from ScheduleFrequency where name = @i_freq );
    
    if @freq_id is null then
		set @freq_id = 1;
    end if;
    
	set @i_orig = JSON_UNQUOTE(JSON_EXTRACT(pBrandConfig,'$.Origin'));
	set @orig_id = ( select id from OriginType where name = @i_orig );
    
    set @logo_url = JSON_UNQUOTE(JSON_EXTRACT(pBrandConfig,'$.LogoUrl'));
    
	if @orig_id is null then
		set @orig_id = 1;
    end if;
    
    
	INSERT INTO Brand
		(brand_name, brand_key, frequency_id, config_json, origin_id, last_refresh_date, create_date)
	VALUES
		(@brand_name, @bid, @freq_id, pBrandConfig, @orig_id,  DATE_ADD(@dt,INTERVAL -1 YEAR),  @dt)
	ON DUPLICATE KEY UPDATE
		modified_date  = now();
        
	set @brand_id = ( SELECT LAST_INSERT_ID());
    
    
    if @logo_url is not null and LENGTH(@logo_url) > 0 then
		CALL UpsertBrandLogo(@brand_id, @logo_url);
	end if;
    
    IF pUserId is not null and LENGTH(pUserId) > 0 then
    
		set @user_id = (select id from User where auth0UserId = pUserId );
        
        insert into UserBrand
        (
			user_id, brand_id
        )
        VALUES
        (
			@user_id ,  @brand_id
        );
    
    end if;
    
    select @brand_id as brand_id;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `RegisterAccount`(
	IN pAccountInfo json
)
BEGIN

	-- DECLARE accountUID VARCHAR(64);
	-- DECLARE companyId INT;
	-- DECLARE roleTypeId INT;

	set @email = JSON_UNQUOTE(JSON_EXTRACT(pAccountInfo,'$.Email'));
	set @auth0UserId = JSON_UNQUOTE(JSON_EXTRACT(pAccountInfo,'$.UserId'));
	set @authSource = JSON_UNQUOTE(JSON_EXTRACT(pAccountInfo,'$.AuthSource'));
	set @firstName = JSON_UNQUOTE(JSON_EXTRACT(pAccountInfo,'$.FirstName'));
	set @lastName = JSON_UNQUOTE(JSON_EXTRACT(pAccountInfo,'$.LastName'));
	set @compName = JSON_UNQUOTE(JSON_EXTRACT(pAccountInfo,'$.CompanyName'));
 	set @roleType = JSON_UNQUOTE(JSON_EXTRACT(pAccountInfo,'$.RoleType'));   
    
	set @lastLogin = JSON_UNQUOTE(JSON_EXTRACT(pAccountInfo,'$.LastLogin'));   
	set @picture = JSON_UNQUOTE(JSON_EXTRACT(pAccountInfo,'$.Picture'));  
   
 	set @loginsCount = JSON_EXTRACT(pAccountInfo,'$.LoginCount');      
  	set @emailVerified = JSON_EXTRACT(pAccountInfo,'$.EmailVerified');     
    
    -- IN emailVerified BIT(1),
    -- IN picture TEXT,

-- get new Account
	SET @accountUID = UUID(); 
    -- create a new account
	INSERT INTO Account(uid, create_date)
	VALUES(@accountUID, NOW());
    -- get Id
	SET @accountId = ( SELECT LAST_INSERT_ID());    
    
-- insert company: if exists use existing else insert new company
	SET @companyId = null;

	if length(@compName) > 0 then
		SET @companyId = ( SELECT id
						   FROM Company
						   WHERE lower(name) = lower(@compName));	

	   IF @companyId is null THEN
			INSERT INTO Company
			(name)
			VALUES 
			(@compName);
            
		   SET @companyId = ( SELECT LAST_INSERT_ID());
		END IF;
	end if;
    

-- get RoleType
	SET @roleTypeId = ( SELECT id
						FROM RoleType
						WHERE lower(name) = lower(@roleType));


-- insert new user
	INSERT INTO User(
		email,
		auth0UserId,
		authSource,
		emailVerified,
		firstName,
		lastName,
		companyId,
		picture,
		lastLogin,
		loginsCount,
		roleTypeId,
		accountId
	)
	Values(
		@email,
		@auth0UserId,
		@authSource,
		@emailVerified,
		@firstName,
		@lastName,
		@companyId,
		@picture,
		@lastLogin,
		@loginsCount,
		@roleTypeId,
		@accountId
	)
	ON DUPLICATE KEY UPDATE
		modified_date  = now();
    
    SELECT @accountId as accountId , @accountUID as accountKey;
    
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `SaveBenchmarkScore`(IN pBenchmarkId INT, IN pScoreType VARCHAR(32), IN pScoreJson json)
BEGIN

	
    set @score_type_id = (select Id 
						from ScoreType 
						where  name = pScoreType);
  
	INSERT INTO BenchmarkScore
    (
		benchmark_id,
        score_type_id,
        score_json
    )
    VALUES
    (
		pBenchmarkId,
		@score_type_id,
        pScoreJson
    ) ON DUPLICATE KEY UPDATE
		score_json = pScoreJson,
		modified_date = NOW();
	
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `SaveBenchmarkSessionResult`(IN pBenchmarkId INT, IN pBenchmarkSessionId INT, IN pResult json, IN pScoreType VARCHAR(32))
BEGIN
		
        set @pScoreTypeId = ( SELECT Id FROM ScoreType WHERE name = pScoreType LIMIT 1 );
        
		INSERT INTO BenchmarkSessionResult
        ( 
			benchmark_id,
            benchmark_session_id,
            result_json,
            result_type_id
        )
		VALUES
		(
			pBenchmarkId, 
            pBenchmarkSessionId, 
            pResult,
            @pScoreTypeId
		)	
        ON DUPLICATE KEY UPDATE
			result_json = pResult,
			modified_date  = now();
  
    
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `SaveBrandArchetypeGoal`(IN pBrandKey VARCHAR(64),
																	IN pArchetypeGoal VARCHAR(32),
                                                                    IN pArchetypeScore json)
BEGIN

	SET @brandId = ( select id
					 from Brand
                     where brand_key = pBrandKey );
                     
	INSERT INTO BrandArchetypeGoal
    (brand_id,  archetype_target, score_json)
	VALUES
    (@brandId, pArchetypeGoal, pArchetypeScore)
	ON DUPLICATE KEY UPDATE
    archetype_target = pArchetypeGoal,
    score_json = pArchetypeScore,
    modified_date = NOW(); 


END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `SaveBrandArchetypeGoal2`(IN pBrandId INT,
																	IN pArchetypeGoal VARCHAR(32),
                                                                    IN pArchetypeScore json)
BEGIN
                     
	INSERT INTO BrandArchetypeGoal
    (brand_id,  archetype_target, score_json)
	VALUES
    (pBrandId, pArchetypeGoal, pArchetypeScore)
	ON DUPLICATE KEY UPDATE
    archetype_target = pArchetypeGoal,
    score_json = pArchetypeScore,
    modified_date = NOW(); 


END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `SaveBrandSessionArchetypeScore`(IN pSessionKey VARCHAR(64), IN pScoreType VARCHAR(32), IN pScoreJson json)
BEGIN
  SET @xist = (SELECT EXISTS(
					SELECT 1
					FROM BrandSessionArchetypeScore
					WHERE session_key =  pSessionKey AND  score_type = pScoreType ));
             
  IF @xist = 1 THEN
		UPDATE BrandSessionArchetypeScore
        SET score_json = pScoreJson,
            modified_date = NOW()
        WHERE session_id =  pSessionKey and score_type = pScoreType;
  ELSE
	
    set @sid = (select Id 
				from BrandSession 
                where session_key = pSessionKey);
  
	INSERT INTO BrandSessionArchetypeScore
    (
		session_id,
        session_key,
        score_type,
        score_json
    )
    VALUES
    (
		@sid,
		pSessionKey,
        pScoreType,
        pScoreJson
    );
  END IF;
	
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `SaveBrandSessionResult`(IN pBrandSessionKey VARCHAR(64), IN pResultType VARCHAR(32), IN pResultJson json)
BEGIN

  SET @pBrandSessionId = ( SELECT Id
							FROM BrandSession
                            WHERE session_key = pBrandSessionKey);

  SET @typeId = ( SELECT Id 
                  FROM ResultType
                  WHERE name = pResultType );
  SET @xist = (SELECT EXISTS(
					SELECT 1
					FROM BrandSessionResult 
					WHERE brand_session_id =  @pBrandSessionId AND  result_type_id = @typeId ));
             
  IF @xist = 1 THEN
		UPDATE BrandSessionResult t1
        JOIN ResultType t2
			ON t1.result_type_id = t2.id
        SET result_json = pResultJson,
            modified_date = NOW()
        WHERE brand_session_id =  @pBrandSessionId and t2.name = pResultType;
  ELSE
	
  
	INSERT INTO BrandSessionResult
    (
		brand_session_id,
        result_type_id,
        result_json
            
    )
    VALUES
    (
		@pBrandSessionId,
		@typeId,
        pResultJson
    );
  END IF;
	
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `UpdateBenchmark`(IN pBrandKey VARCHAR(64),
															 IN pBenchmarkKey VARCHAR(64), 
                                                             IN pBenchmarkConfig json)
BEGIN
	

	UPDATE Benchmark
    SET config_json = pBenchmarkConfig,
		modified_date = NOW()
	WHERE benchmark_key = pBenchmarkKey;
    
    SELECT c.id as brand_id, pBrandKey as brand_key, b.id as benchmark_id, pBenchmarkKey as benchmark_key
    FROM BrandBenchmark a
    JOIN Benchmark b
		ON a.benchmark_id = b.id 
	JOIN Brand c
		ON a.brand_id = c.id and c.brand_key = pBrandKey
	WHERE b.benchmark_key = pBenchmarkKey;
	
 
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `UpdateBenchmarkConfig`(IN pBrandKey VARCHAR(64),
															 IN pBenchmarkKey VARCHAR(64), 
                                                             IN pBenchmarkConfig json)
BEGIN
	

	UPDATE Benchmark
    SET config_json = pBenchmarkConfig,
		status_id = 1,
		modified_date = NOW()
	WHERE benchmark_key = pBenchmarkKey;
    
    SELECT c.id as brand_id, pBrandKey as brand_key, b.id as benchmark_id, pBenchmarkKey as benchmark_key
    FROM BrandBenchmark a
    JOIN Benchmark b
		ON a.benchmark_id = b.id 
	JOIN Brand c
		ON a.brand_id = c.id and c.brand_key = pBrandKey
	WHERE b.benchmark_key = pBenchmarkKey;
	
 
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `UpdateBenchmarkInfo`(IN pBrandId INT,
															 IN pBenchmarkId INT, 
                                                             IN pBenchmarkName VARCHAR(128),
                                                             IN pBenchmarkConfig json)
BEGIN
	

	UPDATE Benchmark
    SET config_json = pBenchmarkConfig,
        name = pBenchmarkName,
		status_id = 1,
		modified_date = NOW()
	WHERE id = pBenchmarkId;
    
    SELECT c.id as brand_id, c.brand_key , b.id as benchmark_id, b.benchmark_key
    FROM BrandBenchmark a
    JOIN Benchmark b
		ON a.benchmark_id = b.id 
	JOIN Brand c
		ON a.brand_id = c.id and c.id = pBrandId
	WHERE b.id = pBenchmarkId;
	
 
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `UpdateBenchmarkStatus`(
	IN pBenchmarkId INT,
    IN pStatusId INT 
)
BEGIN
	
	UPDATE Benchmark
    SET 
        status_id = pStatusId,
		modified_date =  NOW()
	WHERE id = pBenchmarkId; 
        
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `UpdateBrandInfo`(
	IN pBrandId INT,
    IN pInfoJson json 
)
BEGIN

	set @brand_desc = JSON_UNQUOTE(JSON_EXTRACT(pInfoJson,'$.Description'));
	    
    UPDATE Brand
    SET description = @brand_desc
    WHERE id = pBrandId;
        
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `UpdateBrandSessionConfig`(
	IN pBrandId INT,
	IN pBrandSessionId INT,
    IN pConfigJson json 
)
BEGIN
	
	UPDATE BrandSession a
    JOIN Brand b
		ON a.brand_id = b.id AND a.brand_id = pBrandId
    SET 
        a.config_json = pConfigJson
	WHERE a.id = pBrandSessionId; 
    
    UPDATE Brand
    SET config_json = pConfigJson
    WHERE id = pBrandId;
        
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `UpdateBrandSessionStatus`(
	IN pBrandId INT,
	IN pBrandSessionId INT,
    IN pStatusId INT 
)
BEGIN
	
	UPDATE BrandSession a
    JOIN Brand b
		ON a.brand_id = b.id AND a.brand_id = brand_id
    SET 
        a.run_status_id = pStatusId,
		a.modified_date =  NOW()
	WHERE a.id = pBrandSessionId; 
        
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `UpdateBrandSessionStatusByKey`(
	IN pBrandKey VARCHAR(64),
	IN pBrandSessionKey VARCHAR(64),
    IN pStatusId INT 
)
BEGIN
	
	UPDATE BrandSession a
    JOIN Brand b
		ON a.brand_id = b.id AND a.brand_id = brand_id
    SET 
        a.run_status_id = pStatusId,
		a.modified_date =  NOW()
	WHERE a.session_key = pBrandSessionKey; 
        
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `UpdateBrandSessionTaskStatus`(
	IN pBrandId INT,
	IN pBrandSessionId INT,
    IN pSourceId INT,
    IN pBlobId INT,
    IN pStatusId INT 
)
BEGIN
	
	UPDATE BrandSessionTask a
    JOIN BrandSession b
		ON a.brand_session_id = b.id AND a.brand_session_id = pBrandSessionId
	JOIN Brand c
		ON b.brand_id = c.id and b.brand_id = pBrandId
    SET 
		a.content_blob_id = pBlobId,
        a.status_id = pStatusId,
		end_date =  NOW()
	WHERE a.content_source_id = pSourceId; 
        
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `UpdateBrandSetupRequestListStatus`(IN pRequestIdList TEXT, IN newStatus  tinyint(1))
BEGIN

  UPDATE BrandSetupRequest
  Set status_id = newStatus,
      modified_date = now()
  WHERE JSON_CONTAINS(pRequestIdList, CAST(id as JSON));
  

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `UpdateBrandSetupRequestStatus`(IN pRequestId INT, IN newStatus  tinyint)
BEGIN

  UPDATE BrandSetupRequest
  Set status_id = newStatus,
      modified_date = now()
  WHERE id = pRequestId;
  

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `UpdateInterstitialCount`(
	IN pUserId VARCHAR(64)
)
BEGIN
    -- get interstitial count
	SET @interstitialCount = (SELECT interstitialCount
		FROM User
		WHERE auth0UserId = pUserId);	  

	UPDATE User
    SET 
		interstitialCount = IFNULL(@interstitialCount,0) + 1,
		modified_date = now()
	WHERE auth0UserId = pUserId; 
        
	SELECT interstitialCount
		FROM User
		WHERE auth0UserId = pUserId;	 
        
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `UpdatePayment`(
  IN pPaymentMethodId VARCHAR(64),
  IN pUserId VARCHAR(128)
)
BEGIN

    UPDATE Payment a
    JOIN User b
		ON a.user_id = b.id
    SET paymentMethodId = pPaymentMethodId
    WHERE b.auth0UserId = pUserId;
        
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `UpdateUserAccountLevel`(
	IN pUserId VARCHAR(128),
	IN pAccountLevel smallint(6)
)
BEGIN
   
   -- find accountId for the user by email
	SET @accountId = null;

	IF length(pUserId) > 0 then
		SET @accountId = ( SELECT accountId
						   FROM User
						   WHERE lower(auth0UserId) = lower(pUserId));	

		IF @accountId is not null THEN
			UPDATE Account
			SET
				level_id = pAccountLevel,
				modified_date = now()
			WHERE id = @accountId;
            commit;
		END IF;
	END IF;

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `UpdateUserProfileInfo`(
	IN pUserId VARCHAR(64),
	IN pUserProfileInfo json
)
BEGIN
	
	set @company = JSON_UNQUOTE(JSON_EXTRACT(pUserProfileInfo,'$.Company'));
	set @firstName = JSON_UNQUOTE(JSON_EXTRACT(pUserProfileInfo,'$.FirstName'));
	set @lastName = JSON_UNQUOTE(JSON_EXTRACT(pUserProfileInfo,'$.LastName'));
    set @phone = JSON_UNQUOTE(JSON_EXTRACT(pUserProfileInfo,'$.Phone'));
   
   -- insert company: if exists use existing else insert new company
	SET @companyId = null;

	if length(@company) > 0 then
		SET @companyId = ( SELECT id
						   FROM Company
						   WHERE lower(name) = lower(@company));	

	   IF @companyId is null THEN
			INSERT INTO Company
			(name)
			VALUES 
			(@company);
            
		   SET @companyId = ( SELECT LAST_INSERT_ID());
		END IF;
	end if;
    

	UPDATE User
    SET 
		firstName = CASE WHEN @firstName is not null and length(@firstName) > 0 THEN @firstName END,
		lastName =  CASE WHEN @lastName is not null and length(@lastName) > 0 THEN @lastName END,
		phone = CASE WHEN @phone is not null and length(@phone) > 0 THEN @phone END,
        companyId = CASE WHEN @companyId is not null and length(@companyId) > 0 THEN @companyId END,
		modified_date = now()
	WHERE auth0UserId = pUserId; 
        
END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `UpsertBrandLogo`(IN pBrandId INT, 
                                                             IN pBrandLogoUrl varchar(1024)
                                                             )
BEGIN
	
    
	INSERT INTO BrandLogo
		(brand_id, brand_logo_url)
	VALUES
		(pBrandId, pBrandLogoUrl)
	ON DUPLICATE KEY UPDATE
		brand_logo_url = pBrandLogoUrl,
		modified_date  = now();
	

END$$
DELIMITER ;

DELIMITER $$
CREATE  PROCEDURE `UpsertNewContentSource`( 
                                                             IN pSourceHandle VARCHAR(128),
                                                             IN pSourceType VARCHAR(128))
BEGIN
	
	set@src_type_id = (select Id from ChannelType where name = pSourceType );
    
	set @src_id = ( SELECT a.id
					from ContentSource a
					JOIN ChannelType b
						on a.channel_type_id = b.id
					WHERE a.handle_id = pSourceHandle and  b.id = @src_type_id );
    
     if @src_id is null then
		INSERT INTO ContentSource
			(channel_type_id, handle_id)
		VALUES
			(@src_type_id, pSourceHandle);
    end if;
     

END$$
DELIMITER ;
