require "test_helper"

class QuestionnaireSubmissionsControllerTest < ActionDispatch::IntegrationTest
  test "submits the progressive client questionnaire" do
    contact_answers = {
      "contact" => {
        "project_address" => "Lake Wylie, SC",
        "best_times" => "Weekday evenings",
        "time_zone" => "Eastern"
      },
      "household" => {
        "members" => ["Two adults", "Children", "Pets"],
        "children_status" => ["Children currently in the home"],
        "children_ages" => "10, 12",
        "pet_types" => ["Dog(s)"],
        "pet_count" => "1"
      },
      "lifestyle" => {
        "work_from_home" => "1-2 days/week",
        "work_from_home_count" => "1",
        "host_guests" => "Occasionally",
        "hosting_types" => ["Family gatherings"],
        "type" => "Family-focused"
      }
    }

    get new_questionnaire_submission_path
    assert_response :success

    post questionnaire_submissions_path, params: {
      current_step: "1",
      next_step: "Continue",
      questionnaire_submission: {
        name: "Mason Roberts",
        email: "mason@example.com",
        phone: "(555) 123-4567",
        preferred_contact: "Email",
        answers: contact_answers
      }
    }
    assert_response :unprocessable_entity
    assert_select "h2", "Home & Project Intent"

    project_answers = {
      "home" => {
        "property_type" => "House",
        "size" => "1,000-2,000 sq ft / 93-186 sqm",
        "ownership" => "Own",
        "spaces" => ["Living Room", "Dining Room", "Kitchen"],
        "project_types" => ["Furnishing + layout refinement"],
        "primary_goals" => ["Improve layout and flow", "Make the home feel cohesive"]
      }
    }

    post questionnaire_submissions_path, params: {
      current_step: "2",
      next_step: "Continue",
      questionnaire_submission: { answers: project_answers }
    }
    assert_response :unprocessable_entity
    assert_select "h2", "Function & Priorities"

    priority_answers = {
      "priorities" => {
        "top_priorities" => ["Comfortable everyday living", "Low clutter / better organization"],
        "what_does_not_work" => "The living and dining areas feel disconnected."
      },
      "storage" => {
        "challenges" => ["Entry/shoes/coats"],
        "organization_preference" => "A mix of open + closed storage"
      },
      "space_use" => {
        "preference" => "A balance of both",
        "maintenance_preference" => "Balanced"
      }
    }

    post questionnaire_submissions_path, params: {
      current_step: "3",
      next_step: "Continue",
      questionnaire_submission: { answers: priority_answers }
    }
    assert_response :unprocessable_entity
    assert_select "h2", "Design Direction"

    design_answers = {
      "design" => {
        "style_direction" => ["Transitional", "Scandinavian / Japandi"],
        "mood" => ["Warm and cozy", "Light and airy"],
        "contrast" => "Medium contrast",
        "color_preference" => "Neutral base with color accents",
        "colors_love" => "Warm neutrals and soft green",
        "colors_avoid" => "Harsh brights",
        "materials" => ["Natural wood (medium/warm)", "Linen"],
        "finish_preference" => "Satin",
        "pattern_preference" => "Some pattern, used sparingly",
        "walk_in_feeling" => "Warm, calm, and collected."
      }
    }

    post questionnaire_submissions_path, params: {
      current_step: "4",
      next_step: "Continue",
      questionnaire_submission: { answers: design_answers }
    }
    assert_response :unprocessable_entity
    assert_select "h2", "Rooms, Budget & Logistics"

    room_answers = {
      "rooms" => [
        {
          "name" => "Living Room",
          "functions" => ["Family time", "Entertaining"],
          "current_issues" => ["Poor layout", "Not enough storage"],
          "must_have_features" => "Built-in storage and comfortable seating.",
          "desired_atmosphere" => "Calm but durable for family use."
        }
      ],
      "budget" => {
        "estimated_budget" => "$25,000-$50,000",
        "approach" => "Some flexibility",
        "invest_more" => ["Sofa and key seating"],
        "save_on" => ["Accessories and decor"],
        "open_to" => ["Vintage/secondhand items"]
      },
      "logistics" => {
        "start_date" => "Fall 2026",
        "completion_date" => "Before holidays",
        "fixed_deadlines" => "Family gathering in December",
        "living_during_project" => "Yes",
        "constraints" => ["Delivery restrictions"]
      },
      "working_style" => {
        "decision_making" => ["I'm moderately involved and approve key decisions"],
        "concerns" => ["Budget overruns"],
        "anything_else" => "We want a home that feels elevated but lived in.",
        "questions" => "What is the expected timeline?"
      }
    }

    post questionnaire_submissions_path, params: {
      current_step: "5",
      next_step: "Continue",
      questionnaire_submission: { answers: room_answers }
    }
    assert_response :unprocessable_entity
    assert_select "h2", "Review & Submit"

    assert_difference "QuestionnaireSubmission.count", 1 do
      post questionnaire_submissions_path, params: {
        current_step: "6",
        questionnaire_submission: { answers: {} }
      }
    end
    assert_redirected_to contact_path
    assert_equal flash[:notice], "Thank you. Your client questionnaire has been submitted."

    submission = QuestionnaireSubmission.last
    assert_equal "Mason Roberts", submission.name
    assert_equal "mason@example.com", submission.email
    assert_equal "Lake Wylie, SC", submission.answers.dig("contact", "project_address")
    assert_equal "Living Room", submission.answers.dig("rooms", 0, "name")
  end
end
