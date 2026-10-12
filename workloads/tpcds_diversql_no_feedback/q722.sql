/* Goal: Identify item‑gender combinations where store returns and web returns have the same total return amount and count, then enrich those combinations with any promotional information (including unmatched promotions) using a full outer join. */
WITH sr_agg AS (
    SELECT
        i.i_item_id,
        cd.cd_gender,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt > 0
    GROUP BY CUBE (i.i_item_id, cd.cd_gender)
),
wr_agg AS (
    SELECT
        i.i_item_id,
        cd.cd_gender,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt > 0
    GROUP BY CUBE (i.i_item_id, cd.cd_gender)
),
promo_item AS (
    SELECT
        i.i_item_id,
        p.p_promo_name,
        p.p_discount_active
    FROM promotion p
    FULL OUTER JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y' OR p.p_discount_active IS NULL
)
SELECT
    inter.i_item_id,
    inter.cd_gender,
    inter.total_return_amt,
    inter.return_cnt,
    pi.p_promo_name,
    pi.p_discount_active
FROM (
    SELECT i_item_id, cd_gender, total_return_amt, return_cnt
    FROM sr_agg
    INTERSECT
    SELECT i_item_id, cd_gender, total_return_amt, return_cnt
    FROM wr_agg
) inter
FULL OUTER JOIN promo_item pi ON inter.i_item_id = pi.i_item_id
ORDER BY inter.i_item_id, inter.cd_gender
LIMIT 100
