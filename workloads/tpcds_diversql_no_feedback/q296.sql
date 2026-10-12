WITH joined AS (
    SELECT
        c.c_customer_id,
        d.d_date,
        d.d_year,
        t.t_hour,
        i.i_item_id,
        i.i_brand,
        cd.cd_gender,
        w.w_state,
        sr.sr_return_amt,
        sr.sr_net_loss,
        ws.ws_net_paid,
        ws.ws_quantity
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
      ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_sold_time_sk = t.t_time_sk
     AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 18
      AND i.i_brand = 'Brand#23'
      AND cd.cd_gender = 'M'
      AND ws.ws_quantity > 1
      AND w.w_state = 'CA'
)
SELECT
    c_customer_id,
    d_date,
    i_item_id,
    sr_return_amt AS amount,
    ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY d_date DESC) AS rank_val,
    SUM(sr_return_amt) OVER (PARTITION BY c_customer_id) AS total_val,
    grp
FROM joined
CROSS JOIN (SELECT 1 AS grp UNION ALL SELECT 2 AS grp) AS g
UNION DISTINCT
SELECT
    c_customer_id,
    d_date,
    i_item_id,
    ws_net_paid AS amount,
    DENSE_RANK() OVER (PARTITION BY c_customer_id ORDER BY ws_net_paid DESC) AS rank_val,
    SUM(ws_net_paid) OVER (PARTITION BY c_customer_id) AS total_val,
    grp
FROM joined
CROSS JOIN (SELECT 1 AS grp UNION ALL SELECT 2 AS grp) AS g
ORDER BY total_val DESC, c_customer_id
LIMIT 100
