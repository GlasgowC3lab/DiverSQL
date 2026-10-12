WITH store_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        cd.cd_gender AS gender,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_units = 'Bundle'
      AND cd.cd_marital_status = 'M'
    GROUP BY i.i_item_id, i.i_item_desc, cd.cd_gender
    HAVING SUM(sr.sr_return_amt) > 1000
),
catalog_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        cd.cd_gender AS gender,
        SUM(cr.cr_return_amount) AS total_return_amt,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_units = 'Bundle'
      AND cd.cd_marital_status = 'M'
    GROUP BY i.i_item_id, i.i_item_desc, cd.cd_gender
    HAVING SUM(cr.cr_return_amount) > 500
)
SELECT
    u.item_id,
    u.item_desc,
    u.gender,
    u.total_return_amt,
    u.total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY u.item_id ORDER BY u.total_return_amt DESC) AS rank_per_item
FROM (
    SELECT
        item_id,
        item_desc,
        gender,
        total_return_amt,
        total_net_loss
    FROM store_agg
    UNION
    SELECT
        item_id,
        item_desc,
        gender,
        total_return_amt,
        total_net_loss
    FROM catalog_agg
) u
ORDER BY u.total_return_amt DESC
LIMIT 100
