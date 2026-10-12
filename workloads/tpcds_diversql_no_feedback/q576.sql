/*
Goal: Analyze high‑value returns for the year 2002, focusing on California stores, items sold in "Cup" units, and households in higher income bands. The query joins all eight selected TPC‑DS tables, applies several realistic filters, aggregates return metrics, assigns a global row number, and returns the top 100 rows ordered by total net loss.
*/
WITH union_returns AS (
    /* Store returns side */
    SELECT
        s.s_state                               AS state,
        i.i_category                            AS category,
        ib.ib_income_band_sk                    AS income_band_sk,
        sr.sr_net_loss                          AS net_loss,
        sr.sr_return_amt                        AS return_amt,
        sr.sr_ticket_number                     AS txn_id
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    /* store closed date to date_dim (different alias) */
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    /* catalog page linked through the same return date */
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
        AND cp.cp_end_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND ib.ib_upper_bound >= 80000
      AND i.i_units = 'Cup'
      AND s.s_state = 'CA'
      AND hd.hd_vehicle_count >= 2
      AND cp.cp_type = 'PROMO'

    UNION

    /* Web returns side */
    SELECT
        s.s_state                               AS state,
        i.i_category                            AS category,
        ib.ib_income_band_sk                    AS income_band_sk,
        wr.wr_net_loss                          AS net_loss,
        wr.wr_return_amt                        AS return_amt,
        wr.wr_order_number                      AS txn_id
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    /* store linked via its closed‑date surrogate key */
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
        AND cp.cp_end_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND ib.ib_upper_bound >= 80000
      AND i.i_units = 'Cup'
      AND s.s_state = 'CA'
      AND hd.hd_vehicle_count >= 2
      AND cp.cp_type = 'PROMO'
),
agg AS (
    SELECT
        state,
        category,
        income_band_sk,
        COUNT(DISTINCT txn_id)          AS distinct_txn_count,
        SUM(net_loss)                   AS total_net_loss,
        AVG(return_amt)                 AS avg_return_amount
    FROM union_returns
    GROUP BY state, category, income_band_sk
)
SELECT
    state,
    category,
    income_band_sk,
    distinct_txn_count,
    total_net_loss,
    avg_return_amount,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS rn
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
