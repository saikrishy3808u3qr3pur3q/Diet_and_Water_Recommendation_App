from flask import Flask, request, jsonify
import numpy as np
import pandas as pd
import json
import math    
import joblib
from datetime import datetime

app = Flask(__name__)

# Load the trained model
linear_regression_model = joblib.load(r"F:\Diet_Recommendation_app\Backend\linear_regression_model.pkl")
df = pd.read_csv(r"C:\Users\Saikrishnan.000\Downloads\final_csv.csv")

# In-memory tracker
user_nutrition_tracker = {
    "recommended_water": 0.0,
    "food_based_water": 0.0,  # Track consumed water
    "water_split": {},
    "calorie_split": {},
    "original_calorie_split": {},
    "logged_meals": {},
    "consumed_calories": 0.0,
    "total_daily_calories": 0.0,
    "recommended_macros": {},
    "consumed_macros": {  # Track consumed macros
        "total_fat": 0.0,
        "sugar": 0.0,
        "sodium": 0.0,
        "protein": 0.0,
        "saturated_fat": 0.0,
        "carbohydrates": 0.0,   
        "cholesterol": 0.0,
        "fiber": 0.0  # Added fiber tracking
    },
    "heart_condition": False,
    "db": False,
    "mg": True,
    "wl": False,
    "last_logged_date": str(datetime.now().date())
}

# Meal order for redistribution
MEAL_ORDER = ["breakfast", "lunch", "snacks", "dinner"]

# Adjust calories for goal
def adjust_calories_for_goal(calories, weight_goal_kg, weeks):
    calories_per_kg = 7700
    daily_adjustment = (calories_per_kg * weight_goal_kg) / (weeks * 7)
    return calories + daily_adjustment

# Macronutrient breakdown - Added fiber
def calculate_macronutrients(user_calories):
    return {
        "total_fat": (user_calories * 0.30) / 9,
        "sugar": (user_calories * 0.10) / 4,
        "sodium": (user_calories * 0.05) / 4,
        "protein": (user_calories * 0.15) / 4,
        "saturated_fat": (user_calories * 0.10) / 9,
        "carbohydrates": (user_calories * 0.30) / 4,
        "cholesterol": (user_calories * 0.05) / 1,
        "fiber": (user_calories * 0.05) / 2  # Added fiber calculation
    }
def clean_nan(obj):
    if isinstance(obj, float) and math.isnan(obj):
        return None
    if isinstance(obj, dict):
        return {k: clean_nan(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [clean_nan(v) for v in obj]
    return obj

# Water estimation based on consumed macros
def estimate_water_intake(fiber, sodium, protein):
    fiber_water = fiber * 15
    sodium_water = sodium * 0.5
    protein_water = protein * 0.3
    total_ml = fiber_water + sodium_water + protein_water
    return round(total_ml / 1000, 2)

# Water estimation for initial recommendations
def estimate_initial_water(calories, fiber, sodium, protein):
    base_water_ml = calories * 1
    fiber_water = fiber * 15
    sodium_water = sodium * 0.5
    protein_water = protein * 0.3
    total_ml = base_water_ml + fiber_water + sodium_water + protein_water
    return round(total_ml / 1000, 2)
def estimate_water_intake_from_consumed():
    """
    Calculate water intake estimation based on cumulative consumed macros
    """
    consumed_calories = user_nutrition_tracker["consumed_calories"]
    consumed_fiber = user_nutrition_tracker["consumed_macros"]["fiber"]
    consumed_sodium = user_nutrition_tracker["consumed_macros"]["sodium"]
    consumed_protein = user_nutrition_tracker["consumed_macros"]["protein"]
    
    base_water_ml = consumed_calories * 1
    fiber_water = consumed_fiber * 15
    sodium_water = consumed_sodium * 0.5
    protein_water = consumed_protein * 0.3
    total_ml = fiber_water + sodium_water + protein_water
    return round(total_ml / 1000, 2)

# Reset tracker at new day
def check_and_reset_tracker():
    today = str(datetime.now().date())
    if user_nutrition_tracker["last_logged_date"] != today:
        user_nutrition_tracker["logged_meals"] = {}
        user_nutrition_tracker["consumed_calories"] = 0.0
        user_nutrition_tracker["food_based_water"] = 0.0
        user_nutrition_tracker["last_logged_date"] = today
        # Reset calorie_split to original values if they exist
        if "original_calorie_split" in user_nutrition_tracker and user_nutrition_tracker["original_calorie_split"]:
            user_nutrition_tracker["calorie_split"] = user_nutrition_tracker["original_calorie_split"].copy()
        # Reset consumed macros
        for macro in user_nutrition_tracker["consumed_macros"]:
            user_nutrition_tracker["consumed_macros"][macro] = 0.0

# Redistribute calories according to meal order
def redistribute_calories(current_meal, calorie_difference):
    """
    Redistributes calories to future meals based on meal order.
    
    Args:
        current_meal: The meal that was just logged
        calorie_difference: Positive if we need to add more calories to future meals,
                           negative if we need to subtract calories
    """
    # Get the index of the current meal in the meal order
    current_idx = MEAL_ORDER.index(current_meal)
    
    # Get future meals that haven't been logged yet
    future_meals = [meal for meal in MEAL_ORDER[current_idx+1:] 
                   if meal not in user_nutrition_tracker["logged_meals"]]
    
    if not future_meals:
        return  # No future meals to redistribute to
    
    # Calculate original proportions for future meals
    original_future_total = sum(user_nutrition_tracker["original_calorie_split"][meal] for meal in future_meals)
    
    # Redistribute the calorie difference proportionally
    for meal in future_meals:
        if original_future_total > 0:
            proportion = user_nutrition_tracker["original_calorie_split"][meal] / original_future_total
            new_calories = user_nutrition_tracker["calorie_split"][meal] + (calorie_difference * proportion)
            user_nutrition_tracker["calorie_split"][meal] = round(max(0, new_calories), 2)  # Ensure no negative calories

# Update consumed macros from meal nutrients
def update_consumed_macros(nutrients):
    """
    Update the cumulative macronutrient tracker with nutrients from the logged meal
    
    Args:
        nutrients: Dictionary of nutrients from the logged meal
    """
    # Mapping from API nutrients to internal tracking
    nutrient_mapping = {
        "FatContent": "total_fat",
        "SaturatedFatContent": "saturated_fat",
        "CholesterolContent": "cholesterol",
        "SodiumContent": "sodium", 
        "CarbohydrateContent": "carbohydrates",
        "FiberContent": "fiber",
        "SugarContent": "sugar",
        "ProteinContent": "protein"
    }
    
    # Update each macro value
    for api_name, internal_name in nutrient_mapping.items():
        if api_name in nutrients:
            user_nutrition_tracker["consumed_macros"][internal_name] += nutrients.get(api_name, 0)

# Predict Endpoint
@app.route("/predict", methods=["POST"])
def predict():
    try:
        data = request.get_json()
        attributes = data["attributes"]
        weight_goal_kg = data.get("weight_goal_kg", 0)
        user_nutrition_tracker["heart_condition"] = data.get("heart_condition", 0)
        user_nutrition_tracker["db"] = data.get("db", 0)
        user_nutrition_tracker["mg"] = data.get("mg", 0)
        user_nutrition_tracker["wl"] = data.get("wl", 0)
        
        weeks = data.get("weeks", 1)

        features = np.array([[attributes["age"], attributes["weight"], attributes["height"],
                              attributes["BMI"], attributes["BMR"], attributes["activity_level"],
                              attributes["gender_F"], attributes["gender_M"]]])

        base_calories = linear_regression_model.predict(features)[0]
        adjusted_calories = adjust_calories_for_goal(base_calories, weight_goal_kg, weeks)
        macros = calculate_macronutrients(adjusted_calories)
        water_liters = estimate_initial_water(adjusted_calories, 0,
                                             0, 0)

        # Daily reset
        user_nutrition_tracker["logged_meals"] = {}
        user_nutrition_tracker["consumed_calories"] = 0.0
        user_nutrition_tracker["food_based_water"] = 0.0
        user_nutrition_tracker["total_daily_calories"] = adjusted_calories
        user_nutrition_tracker["recommended_macros"] = macros  # Store recommended macros
        user_nutrition_tracker["recommended_water"] = water_liters
        
        # Reset consumed macros
        for macro in user_nutrition_tracker["consumed_macros"]:
            user_nutrition_tracker["consumed_macros"][macro] = 0.0
            
        user_nutrition_tracker["last_logged_date"] = str(datetime.now().date())

        # Set split
        calorie_split = {
            "breakfast": round(adjusted_calories * 0.25, 2),
            "lunch": round(adjusted_calories * 0.35, 2),
            "snacks": round(adjusted_calories * 0.15, 2),
            "dinner": round(adjusted_calories * 0.25, 2)
        }
        
        # Ensure calorie split equals adjusted calories by adjusting the last meal
        total_split = sum(calorie_split.values())
        if total_split != adjusted_calories:
            calorie_split["dinner"] += round(adjusted_calories - total_split, 2)
        
        user_nutrition_tracker["calorie_split"] = calorie_split
        user_nutrition_tracker["original_calorie_split"] = calorie_split.copy()

        # Initial water split
        user_nutrition_tracker["water_split"] = {
            "breakfast": round(water_liters * 0.25, 2),
            "lunch": round(water_liters * 0.35, 2),
            "snacks": round(water_liters * 0.15, 2),
            "dinner": round(water_liters * 0.25, 2)
        }

        return jsonify({
            "base_calories": round(base_calories, 2),
            "adjusted_calories": round(adjusted_calories, 2),
            "macronutrients": macros,
            "recommended_water_liters": water_liters,
            "calorie_split": user_nutrition_tracker["calorie_split"],
            "water_split_liters": user_nutrition_tracker["water_split"]
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 400


# Log a meal
@app.route("/log_meal", methods=["POST"])
def log_meal():
    try:
        check_and_reset_tracker()

        data = request.get_json()
        meal = data["meal_type"]
        nutrients = data["nutrients"]

        if meal in user_nutrition_tracker["logged_meals"]:
            return jsonify({"error": f"{meal.capitalize()} already logged."}), 400

        # Get actual calories consumed for this meal
        consumed_cal = nutrients.get("Calories", 0)
        
        # Get the expected calories for this meal based on the current calorie split
        expected_cal = user_nutrition_tracker["calorie_split"][meal]
        
        # Calculate the difference (positive means excess, negative means deficit)
        calorie_difference = expected_cal - consumed_cal
        
        # Update logged meals and update total consumed calories
        user_nutrition_tracker["logged_meals"][meal] = nutrients
        user_nutrition_tracker["consumed_calories"] += consumed_cal

        # ✅ Store meal under its direct key as well
        user_nutrition_tracker[meal] = {
            "calories": consumed_cal,
            "nutrients": nutrients
        }

        # Update cumulative macronutrient tracking
        update_consumed_macros(nutrients)
        
        # Set this meal's calorie split to its actual consumed calories
        user_nutrition_tracker["calorie_split"][meal] = consumed_cal
        
        # Redistribute the calorie difference to future meals
        redistribute_calories(meal, calorie_difference)
        
        # Recalculate water needed based on actual consumed macros
        actual_water_needed = estimate_water_intake_from_consumed()
        user_nutrition_tracker["food_based_water"] = actual_water_needed
        
        # Verify the calorie split matches the total daily calories
        total_split = sum(user_nutrition_tracker["calorie_split"].values())
        remaining_unlogged = [m for m in MEAL_ORDER if m not in user_nutrition_tracker["logged_meals"]]
        
        # Adjust the last unlogged meal to ensure total equals target daily calories
        if remaining_unlogged and abs(total_split - user_nutrition_tracker["total_daily_calories"]) > 0.01:
            diff = user_nutrition_tracker["total_daily_calories"] - total_split
            last_meal = remaining_unlogged[-1]
            user_nutrition_tracker["calorie_split"][last_meal] += round(diff, 2)
        
        # Calculate remaining calories
        remaining_calories = user_nutrition_tracker["total_daily_calories"] - user_nutrition_tracker["consumed_calories"]

        # Calculate percentage of macros consumed 
        macro_percentages = {}
        for macro, consumed in user_nutrition_tracker["consumed_macros"].items():
            recommended = user_nutrition_tracker["recommended_macros"].get(macro, 0)
            if recommended > 0:
                macro_percentages[macro] = round((consumed / recommended) * 100, 1)
            else:
                macro_percentages[macro] = 0

        print("\n--- User Nutrition Tracker Snapshot ---")
        print(json.dumps(user_nutrition_tracker, indent=2))
        print("----------------------------------------\n")

        return jsonify({
            "message": f"{meal.capitalize()} logged successfully.",
            "updated_calorie_split": user_nutrition_tracker["calorie_split"],
            "water_based_on_consumed_macros": actual_water_needed,
            "food_based_water": round(user_nutrition_tracker["food_based_water"], 2),
            "remaining_water": round(user_nutrition_tracker["recommended_water"] + actual_water_needed, 2),
            "remaining_calories": round(remaining_calories, 2),
            "consumed_calories": round(user_nutrition_tracker["consumed_calories"], 2),
            "total_daily_calories": round(user_nutrition_tracker["total_daily_calories"], 2),
            "consumed_macros": {k: round(v, 2) for k, v in user_nutrition_tracker["consumed_macros"].items()},
            "recommended_macros": {k: round(v, 2) for k, v in user_nutrition_tracker["recommended_macros"].items()},
            "macro_percentages": macro_percentages
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route('/search', methods=['GET'])
def search_food():
    query = request.args.get('query', '').strip().lower()
    if not query:
        return jsonify({'error': 'Query parameter is required.'}), 400

    matching_foods = df[df['Name'].str.lower().str.startswith(query)]
    
    top_matches = matching_foods.head(10).to_dict(orient='records')

    return jsonify(clean_nan({'results': top_matches}))
@app.route("/recommend", methods=["GET"])
def recommend_meals():
    try:
        remaining_meals = [m for m in MEAL_ORDER if m not in user_nutrition_tracker["logged_meals"]]

        if not remaining_meals:
            return jsonify({"error": "All meals already logged."}), 400

        df = pd.read_csv(r"C:\Users\Saikrishnan.000\Downloads\final_csv.csv")

        # Macro fields to match
        macro_fields = [
            "Calories_per_100g", "FatContent_per_100g", "SaturatedFatContent_per_100g",
            "CholesterolContent_per_100g", "SodiumContent_per_100g", "CarbohydrateContent_per_100g",
            "FiberContent_per_100g", "SugarContent_per_100g", "ProteinContent_per_100g"
        ]

        # Calculate remaining macros
        remaining_macros = {}
        for macro, recommended in user_nutrition_tracker["recommended_macros"].items():
            consumed = user_nutrition_tracker["consumed_macros"].get(macro, 0)
            remaining_macros[macro] = max(recommended - consumed, 0)

        # Calculate remaining calories for each meal
        remaining_cals = {
            meal: user_nutrition_tracker["calorie_split"][meal]
            for meal in remaining_meals
        }

        # Filter based on preferences
        pref_filters = ["heart_condition", "db", "mg", "wl"]
        for pref in pref_filters:
            if user_nutrition_tracker.get(pref):
                df = df[df[pref] == 1]

        recommendations = {}
        used_recipe_names = set()

        for meal in remaining_meals:
            target_cal = remaining_cals[meal]

            # Exclude previously used recipes
            df_filtered = df[~df["Name"].isin(used_recipe_names)].copy()

            # Sort by closeness to target calories, then protein descending
            df_filtered["calorie_diff"] = (df_filtered["Calories_per_100g"] - target_cal).abs()
            df_sorted = df_filtered.sort_values(by=["calorie_diff", "ProteinContent_per_100g"], ascending=[True, False])

            if not df_sorted.empty:
                selected = df_sorted.iloc[0]
                used_recipe_names.add(selected["Name"])

                quantity = round((target_cal / selected["Calories_per_100g"]) * 100, 2)

                # Estimate macros based on calculated quantity
                estimated_macros = {
                    "calories": round((selected["Calories_per_100g"] * quantity) / 100, 2),
                    "total_fat": round((selected["FatContent_per_100g"] * quantity) / 100, 2),
                    "saturated_fat": round((selected["SaturatedFatContent_per_100g"] * quantity) / 100, 2),
                    "cholesterol": round((selected["CholesterolContent_per_100g"] * quantity) / 100, 2),
                    "sodium": round((selected["SodiumContent_per_100g"] * quantity) / 100, 2),
                    "carbohydrates": round((selected["CarbohydrateContent_per_100g"] * quantity) / 100, 2),
                    "fiber": round((selected["FiberContent_per_100g"] * quantity) / 100, 2),
                    "sugar": round((selected["SugarContent_per_100g"] * quantity) / 100, 2),
                    "protein": round((selected["ProteinContent_per_100g"] * quantity) / 100, 2)
                }

                recommendations[meal] = {
                    "name": selected["Name"],
                    "estimated_quantity_g": quantity,
                    "estimated_macros": estimated_macros
                }

        user_nutrition_tracker["meal_recommendations"] = recommendations

        return jsonify(recommendations)

    except Exception as e:
        return jsonify({"error": str(e)}), 400


if __name__ == "__main__":
    app.run(debug=True, port=5000)