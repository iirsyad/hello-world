-- Configuration values
-- Added after the tables have been created

-- ACCOUNT LEVEL
--
INSERT INTO AccountLevel
( id, name)
SELECT 1, 'Free'
WHERE NOT  EXISTS (SELECT 1 FROM AccountLevel u WHERE u.name = 'Free');

INSERT INTO AccountLevel
( id, name)
SELECT 2, 'Paid'
WHERE NOT  EXISTS (SELECT 1 FROM AccountLevel u WHERE u.name = 'Paid');

INSERT INTO AccountLevel
( id, name)
SELECT 3, 'Small Business'
WHERE NOT  EXISTS (SELECT 1 FROM AccountLevel u WHERE u.name = 'Small Business');

INSERT INTO AccountLevel
( id, name)
SELECT 4, 'Medium Business'
WHERE NOT  EXISTS (SELECT 1 FROM AccountLevel u WHERE u.name = 'Medium Business');

INSERT INTO AccountLevel
( id, name)
SELECT 5, 'Enterprise'
WHERE NOT  EXISTS (SELECT 1 FROM AccountLevel u WHERE u.name = 'Enterprise');

-- ROLE TYPE
-- 
INSERT INTO RoleType
( id, name)
SELECT 1, 'Account Admin'
WHERE NOT  EXISTS (SELECT 1 FROM RoleType u WHERE u.name = 'Account Admin');

INSERT INTO RoleType
( id, name)
SELECT 2, 'Billing Admin'
WHERE NOT  EXISTS (SELECT 1 FROM RoleType u WHERE u.name = 'Billing Admin');

INSERT INTO RoleType
( id, name)
SELECT 3, 'Team Admin'
WHERE NOT  EXISTS (SELECT 1 FROM RoleType u WHERE u.name = 'Team Admin');

INSERT INTO RoleType
( id, name)
SELECT 4, 'Default User'
WHERE NOT  EXISTS (SELECT 1 FROM RoleType u WHERE u.name = 'Default User');


-- CONTENT TYPE
-- 
INSERT INTO ContentType
( id, name)
SELECT 1, 'Web Content'
WHERE NOT  EXISTS (SELECT 1 FROM ContentType u WHERE u.name = 'Web Content');

INSERT INTO ContentType
( id, name)
SELECT 2, 'Social Content'
WHERE NOT  EXISTS (SELECT 1 FROM ContentType u WHERE u.name = 'Social Content');


-- CHANNEL TYPE
-- 
INSERT INTO ChannelType
( id, content_type_id, name)
SELECT 1, 1, 'Domain'
WHERE NOT  EXISTS (SELECT 1 FROM ChannelType u WHERE u.name = 'Domain');

INSERT INTO ChannelType
( id, content_type_id, name)
SELECT 2, 2, 'Twitter'
WHERE NOT  EXISTS (SELECT 1 FROM ChannelType u WHERE u.name = 'Twitter');

INSERT INTO ChannelType
( id, content_type_id, name)
SELECT 3, 2, 'Facebook'
WHERE NOT  EXISTS (SELECT 1 FROM ChannelType u WHERE u.name = 'Facebook');


-- ORIGIN TYPE
-- 
INSERT INTO OriginType
( id, name)
SELECT 1, 'Internal System'
WHERE NOT  EXISTS (SELECT 1 FROM OriginType u WHERE u.name = 'Internal System');

INSERT INTO OriginType
( id, name)
SELECT 2, 'UI'
WHERE NOT  EXISTS (SELECT 1 FROM OriginType u WHERE u.name = 'UI');

INSERT INTO OriginType
( id, name)
SELECT 3, 'Benchmark'
WHERE NOT  EXISTS (SELECT 1 FROM OriginType u WHERE u.name = 'Benchmark');


-- SCHEDULE FREQUENCY
-- 
INSERT INTO ScheduleFrequency
( id, name, day_interval)
SELECT 1, 'One Off', 10000
WHERE NOT  EXISTS (SELECT 1 FROM ScheduleFrequency u WHERE u.name = 'One Off');

INSERT INTO ScheduleFrequency
( id, name, day_interval)
SELECT 2, 'Weekly', 7
WHERE NOT  EXISTS (SELECT 1 FROM ScheduleFrequency u WHERE u.name = 'Weekly');

INSERT INTO ScheduleFrequency
( id, name, day_interval)
SELECT 3, 'Monthly', 30
WHERE NOT  EXISTS (SELECT 1 FROM ScheduleFrequency u WHERE u.name = 'Monthly');

INSERT INTO ScheduleFrequency
( id, name, day_interval)
SELECT 4, 'Quarterly', 90
WHERE NOT  EXISTS (SELECT 1 FROM ScheduleFrequency u WHERE u.name = 'Quarterly');


-- SCORE TYPE
-- 
INSERT INTO ScoreType
( id, name)
SELECT 1, 'Overall'
WHERE NOT  EXISTS (SELECT 1 FROM ScoreType u WHERE u.name = 'Overall');

INSERT INTO ScoreType
( id, name)
SELECT 2, 'Tracking'
WHERE NOT  EXISTS (SELECT 1 FROM ScoreType u WHERE u.name = 'Tracking');

INSERT INTO ScoreType
( id, name)
SELECT 3, 'PerBrand'
WHERE NOT  EXISTS (SELECT 1 FROM ScoreType u WHERE u.name = 'PerBrand');

INSERT INTO ScoreType
( id, name)
SELECT 10, 'benchmark-session-brand-scores'
WHERE NOT  EXISTS (SELECT 1 FROM ScoreType u WHERE u.name = 'benchmark-session-brand-scores');



-- RESULT TYPE
-- 
INSERT INTO ResultType
( id, name)
SELECT 1, 'All Scores'
WHERE NOT  EXISTS (SELECT 1 FROM ResultType u WHERE u.name = 'All Scores');


-- MODULE CONFIGURATION 
-- 
INSERT INTO ModuleConfiguration
( module_name, sub_module_name, type_name, config_json)
SELECT 	'AIdentity', 'Parallel Scoring', 'Z_Score', '{ "z_score_mean" : 1.313712027036896, "z_score_std" : 1.548943730059086 }'
WHERE NOT  EXISTS (SELECT 1 FROM ModuleConfiguration u WHERE u.module_name = 'AIdentity' and u.sub_module_name = 'Parallel Scoring' and u.type_name = 'Z_Score');

INSERT INTO ModuleConfiguration
( module_name, sub_module_name, type_name, config_json)
SELECT 		'AIdentity', 'Parallel Scoring', 'Archtype Keywords', '{"Sage": {"keywords": [ "insight", "contribution", "thinking", "factual", "search", "evidence", "knowledge", "understanding", "regarding", "continual", "accurate", "reason", "truth", "logic", "astute", "superior", "learning", "logical", "thinks", "clear", "obvious", "guide", "guiding"], "weights": [ 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106]}, "Explorer": {"keywords": ["adventure", "adventurous", "seeking", "ambitious", "freedom", "freeing", "curious", "individual", "independent", "explore", "exploring", "restless", "searching", "search", "pioneer", "experiment", "brave", "experience", "away"], "weights": [0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516]}, "Rebel": {"keywords": ["escape", "rebel", "fight", "against", "break"], "weights": [2.02724993135476, 2.02724993135476, 2.02724993135476, 2.02724993135476, 2.02724993135476]}, "Lover": {"keywords": ["intimate", "secret", "sexy", "sex", "private", "exclusive", "skin", "touch", "seduce", "seduction"], "weights": [1.7834020989003727, 1.7834020989003727, 1.7834020989003727, 1.7834020989003727, 1.7834020989003727, 1.7834020989003727, 1.7834020989003727, 1.7834020989003727, 1.7834020989003727, 1.7834020989003727]}, "Jester": {"keywords": ["amusing", "amuse", "play", "funny", "humor", "cheeky", "entertain", "distract", "jest", "jester", "game", "fun", "laugh"], "weights": [0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605]}, "Hero": {"keywords": ["challenge", "struggle", "victory", "win", "fight", "rise", "enemy"], "weights": [1.4710705107830324, 1.4710705107830324, 1.4710705107830324, 1.4710705107830324, 1.4710705107830324, 1.4710705107830324, 1.4710705107830324]}, "Everyperson": {"keywords": ["everyday", "plain", "regular", "normal"], "weights": [8.98584727385372, 8.98584727385372, 8.98584727385372, 8.98584727385372]}, "Magician": {"keywords": ["amazing", "impossible", "impossibly", "magic", "magical", "amaze", "transform", "grand", "impossibility", "vision", "imagine", "imagination"], "weights": [4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168]}, "Caregiver": {"keywords": ["love", "family", "care", "loving", "safe", "protected", "warm", "warmth", "caring", "protect", "protection"], "weights": [1.8591642426916704, 1.8591642426916704, 1.8591642426916704, 1.8591642426916704, 1.8591642426916704, 1.8591642426916704, 1.8591642426916704, 1.8591642426916704, 1.8591642426916704, 1.8591642426916704, 1.8591642426916704]}, "Creator": {"keywords": ["create", "ideal", "perfect", "creation", "creator"], "weights": [1.4648048796447086, 1.4648048796447086, 1.4648048796447086, 1.4648048796447086, 1.4648048796447086]}, "Ruler": {"keywords": ["elite", "exclusive", "exclude", "control", "dominate", "rule", "power", "best", "dominating"], "weights": [1.7434376184307463, 1.7434376184307463, 1.7434376184307463, 1.7434376184307463, 1.7434376184307463, 1.7434376184307463, 1.7434376184307463, 1.7434376184307463, 1.7434376184307463]}, "Innocent": {"keywords": ["happy", "basic", "sunny", "sunshine", "joy", "free", "simple", "happiness"], "weights": [3.38906311515558, 3.38906311515558, 3.38906311515558, 3.38906311515558, 3.38906311515558, 3.38906311515558, 3.38906311515558, 3.38906311515558]}}'
WHERE NOT  EXISTS (SELECT 1 FROM ModuleConfiguration u WHERE u.module_name = 'AIdentity' and u.sub_module_name = 'Parallel Scoring' and u.type_name = 'Archtype Keywords');


-- 
-- t_list_row
TRUNCATE TABLE t_list_row;
insert INTO t_list_row
(_row)
values
(0),(1), (2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13), (14), (15), (16), (17), (18), (19), (20), (21), (22), (23), (24), (25), (26), (27), (28);



