import pandas as pd
import numpy as np
import ast

def clean_movies(path):
    df = pd.read_csv(path)

    # numeric cleaning
    cols_zero = ["budget", "revenue", "runtime"]
    for col in cols_zero:
        df[col] = pd.to_numeric(df[col], errors='coerce').replace(0, np.nan)

    # drop missing
    useless_cols = ["homepage", "poster_path", "tagline", "belongs_to_collection",
                     "adult", "video", "id", "overview", "imdb_id"]

    df = df.drop(columns=[col for col in useless_cols if col in df.columns])
    df = df.dropna(subset=['runtime'])

    # date
    df["release_date"] = pd.to_datetime(df["release_date"], errors="coerce").dt.year

    # json fields
    json_cols = ["genres", "production_companies", "production_countries", "spoken_languages"]
    for col in json_cols:
        df[col] = df[col].apply(
            lambda x: [d["name"] for d in ast.literal_eval(x)] if isinstance(x, str) else []
        )

    # feature engineering
    df["main_genre"] = df["genres"].apply(lambda x: x[0] if len(x) > 0 else None)

    return df
