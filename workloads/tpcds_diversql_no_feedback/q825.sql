WITH returns_combined AS (
    -- Catalog returns portion
    SELECT
        d.d_date AS return_date,
        i.i_item_id AS item_id,
        c.c_customer_id AS customer_id,
        c.c_customer_sk AS customer_sk,
        cr.cr_net_loss AS net_loss,
        r.r_reason_desc AS reason_desc
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND cr.cr_net_loss > 100

    UNION ALL

    -- Web returns portion
    SELECT
        d.d_date AS return_date,
        i.i_item_id AS item_id,
        c.c_customer_id AS customer_id,
        c.c_customer_sk AS customer_sk,
        wr.wr_net_loss AS net_loss,
        r.r_reason_desc AS reason_desc
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND wr.wr_net_loss > 100
)
SELECT
    rc.return_date,
    rc.item_id,
    rc.customer_id,
    rc.net_loss,
    rc.reason_desc
FROM returns_combined rc
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss
    JOIN date_dim sd
        ON ss.ss_sold_date_sk = sd.d_date_sk
    WHERE ss.ss_customer_sk = rc.customer_sk
      AND sd.d_date = rc.return_date
)
ORDER BY rc.net_loss DESC, rc.return_date ASC
LIMIT 100
