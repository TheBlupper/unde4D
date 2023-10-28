using Godot;
using System;
using Google.OrTools.LinearSolver;

public partial class StrengthCalculator : Node
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		GD.Print("Hello from C#!");
	}

	public int[] Solve(Vector2[] strengths, Vector2 target) {
		int n = strengths.Length;
		Solver solver = Solver.CreateSolver("SCIP");
		Variable[] coeffs = solver.MakeIntVarArray(n, 0, 9999);

		for (int i = 0; i < 2; i++) {
			Constraint constraint = solver.MakeConstraint(target[i], target[i]);
			for (int j = 0; j < n; j++) {
				constraint.SetCoefficient(coeffs[j], strengths[j][i]);
			}
		}
		Objective objective = solver.Objective();
		// Minimize total amount of hits
		for (int i = 0; i < n; i++) {
			objective.SetCoefficient(coeffs[i], 1);
		}
		objective.SetMinimization();
		Solver.ResultStatus resultStatus = solver.Solve();
		if (resultStatus != Solver.ResultStatus.OPTIMAL) {
			GD.Print("The problem does not have an optimal solution!");
			return null;
		}
		int[] res = new int[n];
		for (int i = 0; i < n; i++) {
			res[i] = (int)coeffs[i].SolutionValue();
		}
		return res;
	}
}
