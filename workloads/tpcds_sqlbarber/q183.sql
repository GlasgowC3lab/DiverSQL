SELECT wp_web_page_sk,
       wp_url,
       CASE WHEN wp_type = 'protected                                         ' THEN 'TargetType' ELSE 'OtherType' END AS page_type_flag,
       (wp_char_count * 3306) + wp_image_count AS weighted_char_image,
       CASE WHEN wr_return_quantity > 91 THEN 'LargeReturn' ELSE 'SmallReturn' END AS return_size,
       (wr_return_amt + wr_return_tax) * 3303.72 AS total_return_inc_tax,
       CONCAT(wp_url, '?ref=', CAST(wp_web_page_id AS varchar)) AS full_url
FROM web_page
JOIN web_returns ON web_page.wp_web_page_sk = web_returns.wr_web_page_sk
WHERE wp_rec_start_date >= DATE '1997-09-03' AND wp_rec_end_date <= DATE '1999-09-03'
