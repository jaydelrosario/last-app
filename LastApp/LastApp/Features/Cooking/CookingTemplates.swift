// LastApp/Features/Cooking/CookingTemplates.swift
import Foundation

struct CookingTemplateItem {
    let title: String
    let desc: String
    let prepMinutes: Int
    let cookMinutes: Int
    let servings: Int
    let ingredients: [(amount: Double, unit: String?, name: String)]
    let steps: [String]
}

enum CookingTemplates {

    static let groups: [(title: String, templates: [CookingTemplateItem])] = [
        ("Breakfast", [scrambledEggs, overnightOats, avocadoToast]),
        ("Lunch & Dinner", [pastaMarinade, sheetPanChicken, stirFryVeggies]),
        ("Snacks", [smoothie, peanutButterApple]),
    ]

    // MARK: - Breakfast

    static let scrambledEggs = CookingTemplateItem(
        title: "Scrambled Eggs",
        desc: "Fluffy, simple scrambled eggs — ready in 10 minutes.",
        prepMinutes: 2, cookMinutes: 5, servings: 1,
        ingredients: [
            (2, nil, "large eggs"),
            (1, "tbsp", "butter"),
            (2, "tbsp", "milk"),
            (1, "pinch", "salt"),
            (1, "pinch", "black pepper"),
        ],
        steps: [
            "Crack eggs into a bowl, add milk, salt, and pepper. Whisk until combined.",
            "Melt butter in a non-stick pan over medium-low heat.",
            "Pour in the egg mixture. Let it sit undisturbed for 20 seconds.",
            "Using a spatula, gently push the eggs from the edges to the center in slow folds.",
            "Remove from heat while they still look slightly underdone — residual heat finishes them.",
            "Serve immediately.",
        ]
    )

    static let overnightOats = CookingTemplateItem(
        title: "Overnight Oats",
        desc: "Prep the night before for a no-cook breakfast.",
        prepMinutes: 5, cookMinutes: 0, servings: 1,
        ingredients: [
            (0.5, "cup", "rolled oats"),
            (0.5, "cup", "milk"),
            (0.25, "cup", "Greek yogurt"),
            (1, "tbsp", "honey or maple syrup"),
            (0.5, "cup", "fresh berries"),
        ],
        steps: [
            "Add oats, milk, yogurt, and sweetener to a jar or container.",
            "Stir until well combined.",
            "Cover and refrigerate overnight (at least 6 hours).",
            "In the morning, top with fresh berries and enjoy cold.",
        ]
    )

    static let avocadoToast = CookingTemplateItem(
        title: "Avocado Toast",
        desc: "A quick, filling breakfast with healthy fats.",
        prepMinutes: 5, cookMinutes: 3, servings: 1,
        ingredients: [
            (2, "slices", "bread"),
            (1, nil, "ripe avocado"),
            (1, "tsp", "lemon juice"),
            (1, "pinch", "salt"),
            (1, "pinch", "red pepper flakes"),
        ],
        steps: [
            "Toast the bread to your preferred doneness.",
            "Halve the avocado, remove the pit, and scoop flesh into a bowl.",
            "Add lemon juice and salt, then mash with a fork to your preferred consistency.",
            "Spread mashed avocado on the toast.",
            "Finish with a pinch of red pepper flakes.",
        ]
    )

    // MARK: - Lunch & Dinner

    static let pastaMarinade = CookingTemplateItem(
        title: "Pasta with Marinara",
        desc: "A classic 20-minute weeknight dinner.",
        prepMinutes: 5, cookMinutes: 15, servings: 2,
        ingredients: [
            (200, "g", "pasta (any shape)"),
            (2, "cups", "marinara sauce"),
            (1, "tsp", "salt (for pasta water)"),
            (2, "tbsp", "parmesan cheese"),
            (4, "leaves", "fresh basil (optional)"),
        ],
        steps: [
            "Bring a large pot of salted water to a boil.",
            "Add pasta and cook according to package instructions until al dente.",
            "While pasta cooks, warm marinara sauce in a small saucepan over low heat.",
            "Reserve ¼ cup pasta water before draining.",
            "Drain pasta and add to the sauce. Toss to coat, adding pasta water if needed.",
            "Serve topped with parmesan and fresh basil.",
        ]
    )

    static let sheetPanChicken = CookingTemplateItem(
        title: "Sheet Pan Chicken & Veggies",
        desc: "One pan, minimal cleanup. Great for meal prep.",
        prepMinutes: 10, cookMinutes: 25, servings: 2,
        ingredients: [
            (2, nil, "chicken breasts"),
            (2, "cups", "broccoli florets"),
            (1, nil, "bell pepper, sliced"),
            (2, "tbsp", "olive oil"),
            (1, "tsp", "garlic powder"),
            (1, "tsp", "paprika"),
            (1, "pinch", "salt and pepper"),
        ],
        steps: [
            "Preheat oven to 400°F (200°C). Line a sheet pan with foil.",
            "Place chicken and vegetables on the pan.",
            "Drizzle with olive oil, then sprinkle garlic powder, paprika, salt, and pepper over everything.",
            "Toss vegetables to coat; keep chicken separate.",
            "Roast for 22–26 minutes until chicken reaches 165°F internal temperature.",
            "Let rest 5 minutes before slicing.",
        ]
    )

    static let stirFryVeggies = CookingTemplateItem(
        title: "Simple Veggie Stir Fry",
        desc: "Fast, flexible, and works with whatever vegetables you have.",
        prepMinutes: 10, cookMinutes: 10, servings: 2,
        ingredients: [
            (3, "cups", "mixed vegetables (broccoli, carrots, snap peas)"),
            (2, "tbsp", "soy sauce"),
            (1, "tbsp", "sesame oil"),
            (2, "cloves", "garlic, minced"),
            (1, "tsp", "cornstarch"),
            (1, "cup", "rice (cooked)"),
        ],
        steps: [
            "Cook rice according to package instructions.",
            "Mix soy sauce, sesame oil, and cornstarch in a small bowl to make the sauce.",
            "Heat a wok or large skillet over high heat until very hot.",
            "Add a splash of oil, then garlic — stir for 30 seconds.",
            "Add vegetables in order of cooking time (carrots first, snap peas last).",
            "Pour sauce over vegetables and toss for 2–3 minutes until coated and tender-crisp.",
            "Serve immediately over rice.",
        ]
    )

    // MARK: - Snacks

    static let smoothie = CookingTemplateItem(
        title: "Beginner Smoothie",
        desc: "A filling, nutritious blend you can customize easily.",
        prepMinutes: 5, cookMinutes: 0, servings: 1,
        ingredients: [
            (1, nil, "banana"),
            (1, "cup", "frozen berries"),
            (1, "cup", "milk or almond milk"),
            (1, "tbsp", "honey"),
            (0.5, "cup", "Greek yogurt"),
        ],
        steps: [
            "Add all ingredients to a blender.",
            "Blend on high for 30–60 seconds until smooth.",
            "Taste and adjust sweetness with more honey if needed.",
            "Pour and serve immediately.",
        ]
    )

    static let peanutButterApple = CookingTemplateItem(
        title: "Apple & Peanut Butter",
        desc: "No cooking needed. A perfect 5-minute snack.",
        prepMinutes: 3, cookMinutes: 0, servings: 1,
        ingredients: [
            (1, nil, "apple"),
            (2, "tbsp", "peanut butter"),
            (1, "pinch", "cinnamon (optional)"),
        ],
        steps: [
            "Wash and slice the apple into wedges.",
            "Serve with peanut butter for dipping.",
            "Sprinkle with cinnamon if desired.",
        ]
    )
}
