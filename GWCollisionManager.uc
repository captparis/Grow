class GWCollisionManager extends Object
	DLLBind(Collisions);

enum EShapeType {
	SHAPE_POINT, SHAPE_CUBE, SHAPE_SPHERE, SHAPE_CYLINDER
};
struct Shape {
	var EShapeType m_type;
	var Vector m_pos;
	var CQuat m_rot;
	var Vector m_radius;
	/*
	 * Point - (0,0,0)
	 * Cube - (Radius)
	 * Sphere - (Radius,0,0)
	 * Cylinder - (Radius,Height,0)
	 */
};

dllimport final function bool HasCollision(const out Shape shape0,const out Shape shape1);

DefaultProperties
{
}