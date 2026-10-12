/*
  Goal: Evaluate promotional impact by linking promotions to web returns, filtering promotions with names matching a numeric pattern and brands starting with 'A'.
  The query extracts the first word from the item description, splits the description into individual words and counts distinct words per promotion/income‑band.
  It also concatenates brand and product name, cross‑joins a small grade dimension, and orders by total net loss.
*/
WITH promo_item AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_product_name,
        i.i_current_price,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wr.wr_return_amt,
        wr.wr_fee,
        wr.wr_return_quantity,
        wr.wr_net_loss
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(p.p_promo_name, '^Promo[0-9]+')
      AND i.i_brand LIKE 'A%'
)
SELECT
    pi.p_promo_sk,
    pi.p_promo_name,
    pi.ib_lower_bound,
    pi.ib_upper_bound,
    CONCAT(pi.i_brand, ' ', pi.i_product_name) AS brand_product,
    fw.first_word,
    SUM(pi.wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT word) AS distinct_desc_words,
    g.grade
FROM promo_item pi
-- split the item description into an array of words
CROSS JOIN LATERAL (SELECT split(pi.i_item_desc, ' ') AS words) AS s
-- expand the array into one row per word
CROSS JOIN UNNEST(s.words) AS t(word)
-- extract the first word of the description using a regex
CROSS JOIN LATERAL (SELECT regexp_extract(pi.i_item_desc, '(\\w+)', 1) AS first_word) AS fw
-- small static dimension for a cartesian product
CROSS JOIN (SELECT 'Low' AS grade UNION ALL SELECT 'Medium' UNION ALL SELECT 'High') AS g
GROUP BY
    pi.p_promo_sk,
    pi.p_promo_name,
    pi.ib_lower_bound,
    pi.ib_upper_bound,
    pi.i_brand,
    pi.i_product_name,
    fw.first_word,
    g.grade
ORDER BY total_net_loss DESC
LIMIT 100
