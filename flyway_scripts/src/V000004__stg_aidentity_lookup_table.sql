

INSERT INTO AccountLevel
( id, name)
VALUES
( 1, 'Free');

INSERT INTO AccountLevel
( id, name)
VALUES
( 2, 'Paid');

INSERT INTO AccountLevel
( id, name)
VALUES
( 3, 'Small Business');

INSERT INTO AccountLevel
( id, name)
VALUES
( 4, ' Medium Business');

INSERT INTO AccountLevel
( id, name)
VALUES
( 5, 'Enterprise');



INSERT INTO RoleType
( id, name)
VALUES
( 1, 'Account Admin');

INSERT INTO RoleType
( id, name)
VALUES
( 2, 'Billing Admin');

INSERT INTO RoleType
( id, name)
VALUES
( 3, 'Team Admin');

INSERT INTO RoleType
( id, name)
VALUES
( 4, 'Default User');




INSERT INTO ContentType
( id, name)
VALUES
( 1, 'Web Content');

INSERT INTO ContentType
( id, name)
VALUES
( 2, 'Social Content');



INSERT INTO ChannelType
( id, content_type_id, name)
VALUES
( 1, 1, 'Domain');

INSERT INTO ChannelType
( id, content_type_id, name)
VALUES
( 2, 2, 'Twitter');

INSERT INTO ChannelType
( id, content_type_id, name)
VALUES
( 3, 2, 'Facebook');



INSERT INTO OriginType
( id, name)
VALUES
( 1, 'Internal System');

INSERT INTO OriginType
( id, name)
VALUES
( 2, 'UI');

INSERT INTO OriginType
( id, name)
VALUES
( 3, 'Benchmark');



INSERT INTO ScheduleFrequency
( id, name, day_interval)
VALUES
( 1, 'One Off', 10000);

INSERT INTO ScheduleFrequency
( id, name, day_interval)
VALUES
( 2, 'Weekly', 7);

INSERT INTO ScheduleFrequency
( id, name, day_interval)
VALUES
( 3, 'Monthly', 30);

INSERT INTO ScheduleFrequency
( id, name, day_interval)
VALUES
( 4, 'Quarterly', 90);




INSERT INTO ScoreType
( id, name)
VALUES
( 1, 'Overall');

INSERT INTO ScoreType
( id, name)
VALUES
( 2, 'Tracking');

INSERT INTO ScoreType
( id, name)
VALUES
( 3, 'PerBrand');




INSERT INTO ResultType
( id, name)
VALUES
( 1, 'All Scores');




INSERT INTO ModuleConfiguration
( module_name, sub_module_name, type_name, config_json)
VALUES
(
	'AIdentity', 'Parallel Scoring', 'Z_Score', '{ "z_score_mean" : 1.313712027036896, "z_score_std" : 1.548943730059086 }'
);

INSERT INTO ModuleConfiguration
( module_name, sub_module_name, type_name, config_json)
VALUES
(
	'AIdentity', 'Parallel Scoring', 'Archtype Keywords', '{"Sage": {"keywords": [ "insight", "contribution", "thinking", "factual", "search", "evidence", "knowledge", "understanding", "regarding", "continual", "accurate", "reason", "truth", "logic", "astute", "superior", "learning", "logical", "thinks", "clear", "obvious", "guide", "guiding"], "weights": [ 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106, 0.24112311890640106]}, "Explorer": {"keywords": ["adventure", "adventurous", "seeking", "ambitious", "freedom", "freeing", "curious", "individual", "independent", "explore", "exploring", "restless", "searching", "search", "pioneer", "experiment", "brave", "experience", "away"], "weights": [0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516, 0.6898453462982516]}, "Rebel": {"keywords": ["escape", "rebel", "fight", "against", "break"], "weights": [2.02724993135476, 2.02724993135476, 2.02724993135476, 2.02724993135476, 2.02724993135476]}, "Lover": {"keywords": ["intimate", "secret", "sexy", "sex", "private", "exclusive", "skin", "touch", "seduce", "seduction"], "weights": [1.7834020989003727, 1.7834020989003727, 1.7834020989003727, 1.7834020989003727, 1.7834020989003727, 1.7834020989003727, 1.7834020989003727, 1.7834020989003727, 1.7834020989003727, 1.7834020989003727]}, "Jester": {"keywords": ["amusing", "amuse", "play", "funny", "humor", "cheeky", "entertain", "distract", "jest", "jester", "game", "fun", "laugh"], "weights": [0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605, 0.046733426938656605]}, "Hero": {"keywords": ["challenge", "struggle", "victory", "win", "fight", "rise", "enemy"], "weights": [1.4710705107830324, 1.4710705107830324, 1.4710705107830324, 1.4710705107830324, 1.4710705107830324, 1.4710705107830324, 1.4710705107830324]}, "Everyperson": {"keywords": ["everyday", "plain", "regular", "normal"], "weights": [8.98584727385372, 8.98584727385372, 8.98584727385372, 8.98584727385372]}, "Magician": {"keywords": ["amazing", "impossible", "impossibly", "magic", "magical", "amaze", "transform", "grand", "impossibility", "vision", "imagine", "imagination"], "weights": [4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168, 4.691417395495168]}, "Caregiver": {"keywords": ["love", "family", "care", "loving", "safe", "protected", "warm", "warmth", "caring", "protect", "protection"], "weights": [1.8591642426916704, 1.8591642426916704, 1.8591642426916704, 1.8591642426916704, 1.8591642426916704, 1.8591642426916704, 1.8591642426916704, 1.8591642426916704, 1.8591642426916704, 1.8591642426916704, 1.8591642426916704]}, "Creator": {"keywords": ["create", "ideal", "perfect", "creation", "creator"], "weights": [1.4648048796447086, 1.4648048796447086, 1.4648048796447086, 1.4648048796447086, 1.4648048796447086]}, "Ruler": {"keywords": ["elite", "exclusive", "exclude", "control", "dominate", "rule", "power", "best", "dominating"], "weights": [1.7434376184307463, 1.7434376184307463, 1.7434376184307463, 1.7434376184307463, 1.7434376184307463, 1.7434376184307463, 1.7434376184307463, 1.7434376184307463, 1.7434376184307463]}, "Innocent": {"keywords": ["happy", "basic", "sunny", "sunshine", "joy", "free", "simple", "happiness"], "weights": [3.38906311515558, 3.38906311515558, 3.38906311515558, 3.38906311515558, 3.38906311515558, 3.38906311515558, 3.38906311515558, 3.38906311515558]}}'
);



insert INTO t_list_row
(_row)
values
(0),(1), (2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13), (14), (15), (16), (17), (18), (19), (20), (21), (22), (23), (24), (25), (26), (27), (28);

