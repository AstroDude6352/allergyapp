from fastapi import FastAPI, HTTPException
import numpy as np
import pandas as pd
import torch
import networkx as nx
from tensorflow import keras
from tensorflow.keras.models import load_model
from sklearn.ensemble import RandomForestClassifier
import dgl

app = FastAPI()

# Load pre-trained models (Replace with actual paths or training logic)
lstm_model = load_model("lstm_model.h5")  # LSTM for time-series contamination trends
rf_model = RandomForestClassifier()  # Placeholder for ingredient risk classification
gnn_model = None  # Placeholder for GNN model (supply chain)

# Dummy function to initialize a graph for GNN (Replace with actual model)
def load_gnn_model():
    global gnn_model
    gnn_model = dgl.DGLGraph()
    gnn_model.add_nodes(10)  # Example with 10 nodes
    gnn_model.add_edges([0, 1, 2], [1, 2, 3])  # Example edges

load_gnn_model()

@app.post("/predict_risk/")
async def predict_risk(ingredient_data: dict):
    try:
        ingredient_features = np.array(ingredient_data["features"]).reshape(1, -1)

        # LSTM Prediction (Time-Series Risk)
        lstm_risk = lstm_model.predict(ingredient_features)[0][0]

        # Random Forest Classification (Ingredient Risk)
        rf_risk = rf_model.predict_proba(ingredient_features)[0][1]

        # GNN-based Supply Chain Risk (Placeholder)
        gnn_risk = 0.5  # Placeholder score, replace with actual GNN computation

        # Final Risk Score (Weighted Combination)
        total_risk = (0.4 * lstm_risk) + (0.4 * rf_risk) + (0.2 * gnn_risk)

        return {"cross_contamination_risk": total_risk}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

