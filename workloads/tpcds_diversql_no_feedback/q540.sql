WITH
    ss_agg AS (
        SELECT
            ss_item_sk,
            ss_store_sk,
            ss_hdemo_sk,
            ss_addr_sk,
            SUM(ss_ext_sales_price) AS total_sales,
            SUM(ss_quantity) AS total_quantity
        FROM store_sales
        GROUP BY ss_item_sk, ss_store_sk, ss_hdemo_sk, ss_addr_sk
    ),
    wr_agg AS (
        SELECT
            wr_item_sk,
            wr_refunded_hdemo_sk,
            wr_refunded_addr_sk,
            wr_reason_sk,
            SUM(wr_return_amt) AS total_return_amt
        FROM web_returns
        GROUP BY wr_item_sk, wr_refunded_hdemo_sk, wr_refunded_addr_sk, wr_reason_sk
    ),
    combined AS (
        -- Branch 1: store sales >= returns
        SELECT
            i1.i_brand,
            i1.i_category,
            ca1.ca_state,
            hd1.hd_buy_potential,
            r.r_reason_desc,
            ss_agg.total_sales,
            ss_agg.total_quantity,
            wr_agg.total_return_amt
        FROM ss_agg
        JOIN item i1               ON ss_agg.ss_item_sk = i1.i_item_sk                     -- join 1
        JOIN household_demographics hd1 ON ss_agg.ss_hdemo_sk = hd1.hd_demo_sk               -- join 2
        JOIN customer_address ca1  ON ss_agg.ss_addr_sk = ca1.ca_address_sk               -- join 3
        JOIN wr_agg               ON ss_agg.ss_item_sk = wr_agg.wr_item_sk                -- join 4
        JOIN item i2               ON wr_agg.wr_item_sk = i2.i_item_sk                     -- join 5
        JOIN household_demographics hd2 ON wr_agg.wr_refunded_hdemo_sk = hd2.hd_demo_sk   -- join 6
        JOIN customer_address ca2  ON wr_agg.wr_refunded_addr_sk = ca2.ca_address_sk      -- join 7
        JOIN reason r              ON wr_agg.wr_reason_sk = r.r_reason_sk                -- join 8
        JOIN item i1_alias         ON i1.i_item_sk = i2.i_item_sk                         -- join 9
        WHERE ss_agg.total_sales >= wr_agg.total_return_amt
        UNION DISTINCT
        -- Branch 2: store sales < returns
        SELECT
            i1.i_brand,
            i1.i_category,
            ca1.ca_state,
            hd1.hd_buy_potential,
            r.r_reason_desc,
            ss_agg.total_sales,
            ss_agg.total_quantity,
            wr_agg.total_return_amt
        FROM ss_agg
        JOIN item i1               ON ss_agg.ss_item_sk = i1.i_item_sk                     -- join 1
        JOIN household_demographics hd1 ON ss_agg.ss_hdemo_sk = hd1.hd_demo_sk               -- join 2
        JOIN customer_address ca1  ON ss_agg.ss_addr_sk = ca1.ca_address_sk               -- join 3
        JOIN wr_agg               ON ss_agg.ss_item_sk = wr_agg.wr_item_sk                -- join 4
        JOIN item i2               ON wr_agg.wr_item_sk = i2.i_item_sk                     -- join 5
        JOIN household_demographics hd2 ON wr_agg.wr_refunded_hdemo_sk = hd2.hd_demo_sk   -- join 6
        JOIN customer_address ca2  ON wr_agg.wr_refunded_addr_sk = ca2.ca_address_sk      -- join 7
        JOIN reason r              ON wr_agg.wr_reason_sk = r.r_reason_sk                -- join 8
        JOIN item i1_alias         ON i1.i_item_sk = i2.i_item_sk                         -- join 9
        WHERE ss_agg.total_sales < wr_agg.total_return_amt
    )
SELECT
    brand,
    category,
    state,
    buy_potential,
    reason_desc,
    total_sales,
    total_quantity,
    total_return_amt
FROM (
    SELECT
        i_brand AS brand,
        i_category AS category,
        ca_state AS state,
        hd_buy_potential AS buy_potential,
        r_reason_desc AS reason_desc,
        total_sales,
        total_quantity,
        total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_sales DESC) AS rn
    FROM combined
) t
WHERE rn <= 5
ORDER BY brand, total_sales DESC
LIMIT 100
