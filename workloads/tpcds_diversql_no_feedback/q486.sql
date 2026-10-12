WITH closed_2001 AS (
    SELECT
        s.s_state,
        d.d_year,
        COUNT(*) AS closed_store_cnt
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_market_manager = 'Roger Nichols'
      AND s.s_closed_date_sk IN (
          SELECT d2.d_date_sk
          FROM date_dim d2
          WHERE d2.d_holiday = 'N'
      )
    GROUP BY CUBE (s.s_state, d.d_year)
),
closed_2002 AS (
    SELECT
        s.s_state,
        d.d_year,
        COUNT(*) AS closed_store_cnt
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND s.s_market_manager = 'Richard Bell'
      AND s.s_closed_date_sk IN (
          SELECT d2.d_date_sk
          FROM date_dim d2
          WHERE d2.d_holiday = 'N'
      )
    GROUP BY CUBE (s.s_state, d.d_year)
)
SELECT *
FROM closed_2001
UNION ALL
SELECT *
FROM closed_2002
ORDER BY s_state, d_year
LIMIT 100
