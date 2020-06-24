DROP PROCEDURE  IF EXISTS GetUserProfile;	

DELIMITER $$	
CREATE PROCEDURE `GetUserProfile`(IN pUserId VARCHAR(128))	
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
            roleType as roleType,	
            c.id as levelOne,	
            interstitialCount as count1	
	FROM User a	
    join Account b	
		on a.accountId = b.id	
	join AccountLevel c	
		on b.level_id = c.id	
    WHERE auth0UserId = pUserId;	

END$$	
DELIMITER ;