-- Question 1: Identify and treat Duplicates and Nulls
-- Analyze the datsets given
Describe comments ;
Describe follows ;
Describe likes ;
Describe photo_tags ;
Describe photos ;
Describe tags ;
Describe users ;


-- SQL Queries to Check for Duplicates and Null’s

-- 1. users Table
-- •	Check for duplicate usernames:

SELECT username, COUNT(*) AS cnt
FROM users
GROUP BY username
HAVING cnt > 1;

-- •	Check for null usernames (should return no rows):

SELECT *
FROM users
WHERE username IS NULL;

-- 2. photos Table
-- •	Check for duplicate image URLs (if uniqueness is desired):

SELECT image_url, COUNT(*) AS cnt
FROM photos
GROUP BY image_url
HAVING cnt > 1;

-- •	Check for nulls in image_url or user_id:

SELECT *
FROM photos
WHERE image_url IS NULL OR user_id IS NULL;

-- 3. comments Table
-- •	Check for duplicate comments by the same user on the same photo:
-- (This query groups by user_id, photo_id, and comment_text. Adjust if your business logic requires comment uniqueness.)

SELECT user_id, photo_id, comment_text, COUNT(*) AS cnt
FROM comments
GROUP BY user_id, photo_id, comment_text
HAVING cnt > 1;

-- •	Check for nulls in comment_text, user_id, or photo_id:

SELECT *
FROM comments
WHERE comment_text IS NULL OR user_id IS NULL OR photo_id IS NULL;

-- 4. likes Table
-- •	Since likes has a composite primary key, duplicates are prevented.
-- (However, you can still check for any null values if needed.)

SELECT *
FROM likes
WHERE user_id IS NULL OR photo_id IS NULL;

-- 5. follows Table
-- •	Duplicates are prevented by the composite primary key. Check for nulls:

SELECT *
FROM follows
WHERE follower_id IS NULL OR followee_id IS NULL;

-- 6. tags Table
-- •	Duplicates in tag_name are inherently prevented by the UNIQUE constraint. Check for nulls:

SELECT *
FROM tags
WHERE tag_name IS NULL;

-- 7. photo_tags Table
-- •	Duplicates are prevented by the composite primary key. Check for nulls:

SELECT *
FROM photo_tags
WHERE photo_id IS NULL OR tag_id IS NULL;

---------------------------------------------------------------
-- Question 2: Distribution of User Activity Levels
-- (Number of posts, likes, and comments on each user’s posts)
---------------------------------------------------------------
SELECT 
    (SELECT COUNT(*) FROM users) AS total_users,
    (SELECT COUNT(*) FROM photos) AS total_posts,
    (SELECT COUNT(*) FROM likes) AS total_likes,
    (SELECT COUNT(*) FROM comments) AS total_comments,
    (SELECT COUNT(*) FROM photo_tags) AS total_tags;

WITH post_counts AS (
    SELECT user_id, COUNT(*) AS num_posts
    FROM photos
    GROUP BY user_id
),
like_counts AS (
    SELECT p.user_id, COUNT(*) AS num_likes
    FROM likes l
    JOIN photos p ON l.photo_id = p.id
    GROUP BY p.user_id
),
comment_counts AS (
    SELECT p.user_id, COUNT(*) AS num_comments
    FROM comments c
    JOIN photos p ON c.photo_id = p.id
    GROUP BY p.user_id
),
total_counts as (
	Select 
    u.id AS user_id,
    u.username,
    COALESCE(pc.num_posts, 0) AS num_posts,
    COALESCE(lc.num_likes, 0) AS num_likes,
    COALESCE(cc.num_comments, 0) AS num_comments
FROM users u
LEFT JOIN post_counts pc ON u.id = pc.user_id
LEFT JOIN like_counts lc ON u.id = lc.user_id
LEFT JOIN comment_counts cc ON u.id = cc.user_id)
Select Count(user_id) as num_users , Sum(num_posts) as num_posts, Sum(num_likes) as num_likes , Sum(num_comments) as num_comments
from total_counts 
;

---------------------------------------------------------------
-- Question 3: Average Number of Tags per Post
---------------------------------------------------------------
WITH photo_tag_counts AS (
    SELECT p.id,
           COUNT(pt.tag_id) AS tag_count
    FROM photos p
    LEFT JOIN photo_tags pt ON p.id = pt.photo_id
    GROUP BY p.id
)
SELECT 
    ROUND(AVG(tag_count), 2) AS avg_tags_per_post
FROM photo_tag_counts;

---------------------------------------------------------------
-- Question 4: Top 5 Users with the Highest Engagement Rates
-- Engagement rate is defined as (total likes + total comments) per post.
---------------------------------------------------------------
WITH post_counts AS (
    SELECT user_id, COUNT(*) AS post_count
    FROM photos
    GROUP BY user_id
),
like_counts AS (
    SELECT p.user_id, COUNT(*) AS total_likes
    FROM likes l
    JOIN photos p ON l.photo_id = p.id
    GROUP BY p.user_id
),
comment_counts AS (
    SELECT p.user_id, COUNT(*) AS total_comments
    FROM comments c
    JOIN photos p ON c.photo_id = p.id
    GROUP BY p.user_id
),
user_engagement AS (
    SELECT 
        u.id AS user_id,
        u.username,
        COALESCE(pc.post_count, 0) AS total_posts,
        COALESCE(lc.total_likes, 0) AS total_likes,
        COALESCE(cc.total_comments, 0) AS total_comments,
        -- Use NULLIF to avoid division by zero when post_count is zero.
        ROUND((COALESCE(lc.total_likes, 0) + COALESCE(cc.total_comments, 0))
          / NULLIF(COALESCE(pc.post_count, 0), 0), 2) AS engagement_rate
    FROM users u
    LEFT JOIN post_counts pc ON u.id = pc.user_id
    LEFT JOIN like_counts lc ON u.id = lc.user_id
    LEFT JOIN comment_counts cc ON u.id = cc.user_id
)
SELECT *
FROM (
    SELECT *, DENSE_RANK() OVER (ORDER BY engagement_rate DESC) AS engagement_rank
    FROM user_engagement
) ranked_users
WHERE engagement_rank <= 5
ORDER BY engagement_rate DESC;

---------------------------------------------------------------
-- Question 5: Users with the Highest Number of Followers and Followings
---------------------------------------------------------------
WITH follower_counts AS (
    SELECT followee_id AS user_id, COUNT(*) AS followers
    FROM follows
    GROUP BY followee_id
),
following_counts AS (
    SELECT follower_id AS user_id, COUNT(*) AS followings
    FROM follows
    GROUP BY follower_id
)
SELECT 
    u.id AS user_id,
    u.username,
    COALESCE(fc.followers, 0) AS followers,
    COALESCE(fg.followings, 0) AS followings
FROM users u
LEFT JOIN follower_counts fc ON u.id = fc.user_id
LEFT JOIN following_counts fg ON u.id = fg.user_id
ORDER BY followers DESC, followings DESC;

---------------------------------------------------------------
-- Question 6: Average Engagement Rate per Post for Each User
-- Engagement here is defined as (likes + comments) per post.
---------------------------------------------------------------
WITH post_counts AS (
    SELECT user_id, COUNT(*) AS post_count
    FROM photos
    GROUP BY user_id
),
like_counts AS (
    SELECT p.user_id, COUNT(*) AS total_likes
    FROM likes l
    JOIN photos p ON l.photo_id = p.id
    GROUP BY p.user_id
),
comment_counts AS (
    SELECT p.user_id, COUNT(*) AS total_comments
    FROM comments c
    JOIN photos p ON c.photo_id = p.id
    GROUP BY p.user_id
)
SELECT 
    u.id AS user_id,
    u.username,
    COALESCE(pc.post_count, 0) AS total_posts,
    (COALESCE(lc.total_likes, 0) + COALESCE(cc.total_comments, 0)) AS total_engagement,
    ROUND((COALESCE(lc.total_likes, 0) + COALESCE(cc.total_comments, 0))
      / (COALESCE(pc.post_count, 1)), 2) AS avg_engagement_per_post
FROM users u
LEFT JOIN post_counts pc ON u.id = pc.user_id
LEFT JOIN like_counts lc ON u.id = lc.user_id
LEFT JOIN comment_counts cc ON u.id = cc.user_id;

---------------------------------------------------------------
-- Question 7: List of Users Who Have Never Liked Any Post
---------------------------------------------------------------
SELECT 
    u.id AS user_id,
    u.username
FROM users u
LEFT JOIN (SELECT DISTINCT user_id FROM likes) l ON u.id = l.user_id
WHERE l.user_id IS NULL;

---------------------------------------------------------------
-- Question 8: Leveraging User-Generated Content for Personalized Ad Campaigns
-- Aggregate hashtags used by each user based on their posts.
---------------------------------------------------------------
WITH user_tags AS (
    SELECT 
        u.id AS user_id,
        u.username,
        GROUP_CONCAT(DISTINCT t.tag_name ORDER BY t.tag_name SEPARATOR ', ') AS used_tags,
        COUNT(DISTINCT p.id) AS total_posts
    FROM users u
    JOIN photos p ON u.id = p.user_id
    JOIN photo_tags pt ON p.id = pt.photo_id
    JOIN tags t ON pt.tag_id = t.id
    GROUP BY u.id, u.username
)
SELECT *
FROM user_tags;

---------------------------------------------------------------
-- Question 9: Correlations Between User Activity and Content Types
-- Since the schema supports only photos, calculate average engagement per hashtag.
---------------------------------------------------------------
WITH photo_engagement AS (
    SELECT 
        p.id AS photo_id,
        COUNT(DISTINCT l.user_id) AS likes,
        COUNT(DISTINCT c.id) AS comments,
        (COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id)) AS total_engagement
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.id
),
hashtag_engagement AS (
    SELECT 
        t.tag_name,
        AVG(pe.total_engagement) AS avg_engagement
    FROM photo_engagement pe
    JOIN photo_tags pt ON pe.photo_id = pt.photo_id
    JOIN tags t ON pt.tag_id = t.id
    GROUP BY t.tag_name
)
SELECT 
    tag_name,
    ROUND(avg_engagement, 2) AS avg_engagement
FROM hashtag_engagement
ORDER BY avg_engagement DESC;

---------------------------------------------------------------
-- Question 10: Total Number of Likes, Comments, and Photo Tags for Each User
---------------------------------------------------------------
WITH post_counts AS (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
),
like_counts AS (
    SELECT p.user_id, COUNT(*) AS total_likes
    FROM likes l
    JOIN photos p ON l.photo_id = p.id
    GROUP BY p.user_id
),
comment_counts AS (
    SELECT p.user_id, COUNT(*) AS total_comments
    FROM comments c
    JOIN photos p ON c.photo_id = p.id
    GROUP BY p.user_id
),
tag_counts AS (
    SELECT p.user_id, COUNT(*) AS total_tags
    FROM photos p
    JOIN photo_tags pt ON p.id = pt.photo_id
    GROUP BY p.user_id
)
SELECT 
    u.id AS user_id,
    u.username,
    COALESCE(pc.total_posts, 0) AS total_posts,
    COALESCE(lc.total_likes, 0) AS total_likes,
    COALESCE(cc.total_comments, 0) AS total_comments,
    COALESCE(tc.total_tags, 0) AS total_photo_tags
FROM users u
LEFT JOIN post_counts pc ON u.id = pc.user_id
LEFT JOIN like_counts lc ON u.id = lc.user_id
LEFT JOIN comment_counts cc ON u.id = cc.user_id
LEFT JOIN tag_counts tc ON u.id = tc.user_id;

---------------------------------------------------------------
-- Question 11: Rank Users Based on Total Engagement Over the Last Month
-- Engagement is defined as the sum of likes and comments on posts made within the past month.
---------------------------------------------------------------
------------------------------------------------------------

-- First, aggregate posts in the last month
WITH monthly_posts AS (
    SELECT 
        user_id,
        COUNT(*) AS posts
    FROM photos
    WHERE created_dat BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 MONTH) AND CURDATE()
    GROUP BY user_id
),
-- Aggregate likes for posts in the last month
monthly_likes AS (
    SELECT 
        p.user_id,
        COUNT(*) AS likes
    FROM photos p
    JOIN likes l ON p.id = l.photo_id
    WHERE p.created_dat BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 MONTH) AND CURDATE()
    GROUP BY p.user_id
),
-- Aggregate comments for posts in the last month
monthly_comments AS (
    SELECT 
        p.user_id,
        COUNT(*) AS comments
    FROM photos p
    JOIN comments c ON p.id = c.photo_id
    WHERE p.created_dat BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 MONTH) AND CURDATE()
    GROUP BY p.user_id
)
SELECT 
    u.id AS user_id,
    u.username,
    COALESCE(mp.posts, 0) AS posts,
    COALESCE(ml.likes, 0) AS likes,
    COALESCE(mc.comments, 0) AS comments,
    (COALESCE(ml.likes, 0) + COALESCE(mc.comments, 0)) AS total_engagement,
    DENSE_RANK() OVER (ORDER BY (COALESCE(ml.likes, 0) + COALESCE(mc.comments, 0)) DESC) AS engagement_rank
FROM users u
LEFT JOIN monthly_posts mp ON u.id = mp.user_id
LEFT JOIN monthly_likes ml ON u.id = ml.user_id
LEFT JOIN monthly_comments mc ON u.id = mc.user_id
ORDER BY total_engagement DESC;

---------------------------------------------------------------
-- Question 12: Retrieve Hashtags Used in Posts with Highest Average Likes
-- Use a CTE to calculate the average likes per hashtag.
---------------------------------------------------------------
WITH photo_likes AS (
    SELECT 
        pt.tag_id,
        p.id AS photo_id,
        COUNT(l.user_id) AS like_count
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    JOIN photo_tags pt ON p.id = pt.photo_id
    GROUP BY pt.tag_id, p.id
),
avg_likes_per_tag AS (
    SELECT 
        t.tag_name,
        AVG(pl.like_count) AS avg_likes
    FROM photo_likes pl
    JOIN tags t ON pl.tag_id = t.id
    GROUP BY t.tag_name
)
SELECT 
    tag_name,
    ROUND(avg_likes, 2) AS avg_likes
FROM avg_likes_per_tag
ORDER BY avg_likes DESC;

---------------------------------------------------------------
-- Question 13: Retrieve Users Who Started Following Someone After Being Followed by That Person
-- Logic: For user A, if B followed A first (f2) and then A followed B later (f1),
-- we list user A along with both follow timestamps.
---------------------------------------------------------------
SELECT DISTINCT 
    f1.follower_id AS user_id,
    u.username,
    f2.created_at AS reciprocal_follow_time,
    f1.created_at AS follow_initiated_time
FROM follows f1
JOIN follows f2 
  ON f1.follower_id = f2.followee_id 
 AND f1.followee_id = f2.follower_id
JOIN users u ON u.id = f1.follower_id
WHERE f1.created_at < f2.created_at;


-- Additional Queries for Subjective Questions

-- Q2 - 
--  List users with zero posts or very low activity (e.g., no posts, likes, or comments)
WITH user_activity AS (
    SELECT 
        u.id AS user_id,
        u.username,
        COUNT(DISTINCT p.id) AS total_posts,
        COUNT(l.user_id) AS total_likes,
        COUNT(c.id) AS total_comments
    FROM users u
    LEFT JOIN photos p ON u.id = p.user_id
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY u.id, u.username
)
SELECT user_id, username, total_posts, total_likes, total_comments
FROM user_activity
WHERE total_posts = 0 OR (total_likes + total_comments) < 10000;

-- Sub Q4-- 
SELECT HOUR(created_dat) AS post_hour, 
       DAYNAME(created_dat) AS post_day,
       AVG(COALESCE(likes_count, 0) + COALESCE(comments_count, 0)) AS avg_engagement
FROM photos p
LEFT JOIN (
    SELECT photo_id, COUNT(*) AS likes_count 
    FROM likes 
    GROUP BY photo_id
) l ON p.id = l.photo_id
LEFT JOIN (
    SELECT photo_id, COUNT(*) AS comments_count 
    FROM comments 
    GROUP BY photo_id
) c ON p.id = c.photo_id
GROUP BY post_hour, post_day
ORDER BY avg_engagement DESC;

-- SUb Q5 
-- Combine follower counts and engagement to rank potential influencers
WITH follower_counts AS (
    SELECT followee_id AS user_id, COUNT(*) AS followers
    FROM follows
    GROUP BY followee_id
),
user_engagement AS (
    SELECT 
        u.id AS user_id,
        u.username,
        COUNT(DISTINCT p.id) AS total_posts,
        COUNT(l.user_id) AS total_likes,
        COUNT(c.id) AS total_comments,
        ROUND((COUNT(l.user_id) + COUNT(c.id)) / NULLIF(COUNT(DISTINCT p.id), 0), 2) AS engagement_rate
    FROM users u
    LEFT JOIN photos p ON u.id = p.user_id
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY u.id, u.username
)
SELECT 
    ue.user_id,
    ue.username,
    fc.followers,
    ue.total_posts,
    ue.engagement_rate,
    ROUND((fc.followers * ue.engagement_rate), 2) AS influencer_score
FROM user_engagement ue
JOIN follower_counts fc ON ue.user_id = fc.user_id
ORDER BY influencer_score DESC
LIMIT 10;
 

