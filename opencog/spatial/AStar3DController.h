/*
 * opencog/spatial/AStarController.h
 *
 * Copyright (C) 2002-2009 Novamente LLC
 * All Rights Reserved
 * Author: Troy Huang
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License v3 as
 * published by the Free Software Foundation and including the exceptions
 * at http://opencog.org/wiki/Licenses
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program; if not, write to:
 * Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */


/**
 * AStar3DController.h
 *
 * A* 3d pathfinding functionality
 *
 * Current implementation uses LocalSpaceMap2D for map
 * LSMap3DSearchNode implements functionality specific to LocalSpaceMap2D
 * stlastar.h (and fsa.h) contains generic astar algorithm implementation
 * Currently, start and goal coordinates are based on gridpoints,
 * solution path movement is in 10 directions--horizontal, vertical, diagonal,
 * up and down.
 *
 *
 * General usage:
 *    AStar3DController asc;
 *    asc.setMap(map);
 *
 *   asc.setStartAndGoalStates(nodeStart,nodeEnd);
 *    int SearchResult = asc.findPath();
 *
 *    vector<spatial::GridPoint> solution = asc.getSolutionGridPoints();
 *      or
 *    vector<spatial::Point> solution = asc.getSolutionPoints()
 *
 */

#ifndef _SPATIAL_ASTAR3D_CONTROLLER_H_
#define _SPATIAL_ASTAR3D_CONTROLLER_H_

#include <opencog/spatial/LSMap3DSearchNode.h>

#define MAX_SEARCH_NODES 5000
#define DEBUG_LISTS 0
#define DEBUG_LIST_LENGTHS_ONLY 0
#define DISPLAY_SOLUTION 0

namespace opencog
{
    namespace spatial
    {
        class AStar3DController
        {

            //typedef LocalSpaceMap2D<unsigned int, double, boost::hash<unsigned int> > Map;
            typedef LocalSpaceMap2D Map;
            typedef LSMap3DSearchNode MapSearchNode;

        public:
            AStarSearch<MapSearchNode> *astarsearch;

            AStar3DController();
            ~AStar3DController();

            void setMap(Map *map);
            void setStartAndGoalStates(MapSearchNode &startNode, MapSearchNode &goalNode);

            //Create new astarsearch with same start and goal nodes, for testing and comparing different heuristics
            void resetSearch(MapSearchNode &startNode, MapSearchNode &goalNode);

            /**
             * Calculates shortest route path
             * @return int SearchState code (defined in stlastar.h)
             *   enum {
             *    SEARCH_STATE_NOT_INITIALISED,
             *   SEARCH_STATE_SEARCHING,
             *   SEARCH_STATE_SUCCEEDED,
             *   SEARCH_STATE_FAILED,
             *   SEARCH_STATE_OUT_OF_MEMORY,
             *   SEARCH_STATE_INVALID }
             */
            unsigned int findPath();

            void debugLists(unsigned int SearchSteps);

            //get solution path as vector of grid points
            vector<spatial::GridPoint> getSolutionGridPoints();
            //get solution path as vector of distance points
            vector<spatial::Point3D> getSolutionPoints();
            vector<spatial::Point3D> getShortestCalculatedPath();

            //MapSearchNode nodeStart, nodeEnd;
        private:
            bool useFakeSolution;
            vector<MapSearchNode> fakeSolution;
        };

    } // spatial
} // opencog

#endif /*_SPATIAL_ASTAR3D_CONTROLLER_H_*/
